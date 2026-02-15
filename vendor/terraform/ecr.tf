
resource "tls_private_key" "chatapp_cert_key" {
    algorithm = "RSA"
}

resource "tls_self_signed_cert" "chatapp_cert" {
    private_key_pem = tls_private_key.chatapp_cert_key.private_key_pem

    subject {
        common_name  = aws_lb.chatapp.dns_name
    }

    dns_names = [
        aws_lb.chatapp.dns_name
    ]

    validity_period_hours = 43800
    early_renewal_hours = 1

    allowed_uses = [
        "key_encipherment",
        "digital_signature",
        "server_auth",
    ]
}
resource "time_sleep" "wait_30_seconds" {
  depends_on = [tls_self_signed_cert.chatapp_cert]

  create_duration = "30s"
}

resource "local_file" "chatapp_cert" {
    content  = tls_self_signed_cert.chatapp_cert.cert_pem
    filename = "${path.module}/../certs/certificate.crt"
}

resource "aws_acm_certificate" "chatapp_cert" {
    private_key = tls_private_key.chatapp_cert_key.private_key_pem
    certificate_body = tls_self_signed_cert.chatapp_cert.cert_pem
    certificate_chain = null
}



resource "aws_ecr_repository" "backend" {
  name = "chatapp-backend"
  force_delete = true
}

resource "aws_ecr_repository" "frontend" {
  name = "chatapp-frontend"
  force_delete = true
}


resource "null_resource" "docker_builds" {
    triggers = {
      backend_dockerfile  = filemd5("${path.cwd}/../cloud_backend/Dockerfile")
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
