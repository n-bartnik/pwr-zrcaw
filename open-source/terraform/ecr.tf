

resource "local_file" "keycloak_realm_config" {
  filename = "${path.module}/../cloud_keycloak/realm.json"
  content  = jsonencode({
    "id": "chatapp",
    "realm": "chatapp",
    "enabled": true,
    "sslRequired": "external",
    "registrationAllowed": true,
    "users": [
      {
        "username": "user",
        "enabled": true,
        "email": "user@example.com",
        "firstName": "Test",
        "lastName": "User",
        "credentials": [
          {
            "type": "password",
            "value": "password",
            "temporary": false
          }
        ],
        "realmRoles": ["user"]
      }
    ],
    "clients": [
      {
        "clientId": "chatapp-client",
        "enabled": true,
        "clientAuthenticatorType": "client-secret",
        "secret": "uaqjsQH68iBc5l6rFeq1RaBW8FVetyh7",
        "redirectUris": [
          "https://${var.app_domain}/oauth2/idpresponse",
        ],
        "webOrigins": ["+"],
        "standardFlowEnabled": true,
        "implicitFlowEnabled": false,
        "directAccessGrantsEnabled": true,
        "publicClient": false,
        "protocol": "openid-connect",
        "defaultClientScopes": [
          "web-origins",
          "acr",
          "profile",
          "roles",
          "email"
        ]
      }
    ]
  })
}

resource "aws_ecr_repository" "backend" {
  name = "chatapp-backend"
  force_delete = true
}

resource "aws_ecr_repository" "frontend" {
  name = "chatapp-frontend"
  force_delete = true
}

resource "aws_ecr_repository" "grafana" {
  name = "chatapp-grafana"
  force_delete = true
}

resource "null_resource" "docker_builds" {
    triggers = {
      backend_dockerfile = filemd5("${path.cwd}/../cloud_backend/Dockerfile")
      frontend_dockerfile = filemd5("${path.cwd}/../cloud_frontend/Dockerfile")
    }

    provisioner "local-exec" {
      interpreter = ["/bin/bash", "-c"]
        command = <<-EOF
        aws ecr describe-repositories --repository-names ${aws_ecr_repository.backend.name}
        aws ecr describe-repositories --repository-names ${aws_ecr_repository.frontend.name}
        sleep 5
        docker login --username AWS -p $(aws ecr get-login-password --region us-east-1) ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com
        docker build -t ${aws_ecr_repository.backend.repository_url}:latest ../cloud_backend
        docker push ${aws_ecr_repository.backend.repository_url}:latest
        docker build -t ${aws_ecr_repository.frontend.repository_url}:latest ../cloud_frontend
        docker push ${aws_ecr_repository.frontend.repository_url}:latest
        EOF
        
    }
    depends_on = [
        aws_ecr_repository.backend,
        aws_ecr_repository.frontend,
    ]
}


resource "null_resource" "docker_build_grafana" {
  triggers = {
    dockerfile = filemd5("${path.cwd}/../grafana-provisioning/Dockerfile")
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOF
      aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com
      docker build -t ${aws_ecr_repository.grafana.repository_url}:latest ../grafana-provisioning
      docker push ${aws_ecr_repository.grafana.repository_url}:latest
    EOF
  }

  depends_on = [
    aws_ecr_repository.grafana
  ]
}
