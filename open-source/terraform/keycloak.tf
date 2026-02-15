resource "aws_acm_certificate" "decard_cert" {
  private_key       = file("${path.module}/../certs/privkey1.pem")
  certificate_body  = file("${path.module}/../certs/cert1.pem")
  certificate_chain = file("${path.module}/../certs/chain1.pem")

  tags = {
    Name = "decard-imported-cert"
  }
}


resource "aws_ecs_task_definition" "keycloak" {
  family = "chatapp-keycloak"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "1024"
  memory = "2048"
  execution_role_arn = var.lab_role
  task_role_arn = var.lab_role

  container_definitions = jsonencode([
    {
      name = "keycloak"
      image = "quay.io/keycloak/keycloak:21.1.2"
      essential = true
      user = "0"
      entryPoint = ["/bin/sh", "-c"]
      command = [
        "mkdir -p /opt/keycloak/data/import && echo \"$KEYCLOAK_REALM_JSON\" > /opt/keycloak/data/import/realm.json && /opt/keycloak/bin/kc.sh start-dev --import-realm --health-enabled=true"
      ]
      
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]

      environment = [
        { name = "KEYCLOAK_ADMIN", value = "admin2" },
        { name = "KEYCLOAK_ADMIN_PASSWORD", value = "admin123" },
        
        { name = "KC_DB", value = "postgres" },
        { 
          name  = "KC_DB_URL", 
          value = "jdbc:postgresql://${aws_lb.postgres_nlb.dns_name}:5432/chatdb" 
        },
        { name = "KC_DB_USERNAME", value = "chatappuser" },
        { name = "KC_DB_PASSWORD", value = "cPB6DnvyixTWJxif" },
        {
          name  = "KC_DB_POOL_INITIAL_SIZE"
          value = "1"
        },
        {
          name  = "KC_DB_POOL_MIN_SIZE"
          value = "1"
        },
        {
          name  = "KC_DB_POOL_MAX_SIZE"
          value = "10"
        },
        { name = "KC_PROXY", value = "edge" },
        { name = "KC_PROXY_HEADERS", value = "X-Forwarded-Proto" },
        { name = "KC_HTTP_ENABLED", value = "true" },
        { name = "KC_HOSTNAME_STRICT", value = "false" },
        { name = "KC_HOSTNAME_STRICT_HTTPS", value = "false" },
        { 
          name  = "KEYCLOAK_REALM_JSON", 
          value = local_file.keycloak_realm_config.content 
        },
        { name = "KC_HOSTNAME", value = "${var.auth_domain}" },
        {
          name  = "KC_FEATURES"
          value = "token-exchange"
        },
      ]


      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = aws_cloudwatch_log_group.keycloak.name
          "awslogs-region" = "us-east-1"
          "awslogs-stream-prefix" = "keycloak"
        }
      }
      
    }
  ])
}

resource "aws_cloudwatch_log_group" "keycloak" {
  name = "/ecs/chatapp-keycloak"
  retention_in_days = 7
}

resource "aws_ecs_service" "keycloak" {
  name = "keycloak-service"
  cluster = aws_ecs_cluster.chatapp.id
  task_definition = aws_ecs_task_definition.keycloak.arn
  desired_count = 1
  launch_type = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_service.postgres]

  load_balancer {
    target_group_arn = aws_lb_target_group.keycloak.arn
    container_name = "keycloak"
    container_port = 8080
  }
}

