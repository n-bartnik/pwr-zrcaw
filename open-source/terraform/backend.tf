
resource "docker_image" "backend" {
  name = "${aws_ecr_repository.backend.repository_url}:latest"
  build {
    context = "${path.cwd}/../cloud_backend"
    dockerfile = "Dockerfile"
  }
}




resource "aws_ecs_task_definition" "backend" {
  family = "chatapp-backend"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "512"
  memory = "1024"
  execution_role_arn = var.lab_role
  task_role_arn = var.lab_role

  container_definitions = jsonencode([
    {
      name = "backend"
      image = "${aws_ecr_repository.backend.repository_url}:latest"
      essential = true
      environment = [
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${aws_lb.postgres_nlb.dns_name}:5432/chatdb"},
        { name = "SPRING_DATASOURCE_USERNAME", value = "chatappuser" },
        { name = "SPRING_DATASOURCE_PASSWORD", value = "cPB6DnvyixTWJxif" },
        { name = "CORS_ALLOWED_ORIGINS", value = "https://${var.app_domain}" },
        { name = "S3_ENDPOINT", value = "http://${aws_lb.postgres_nlb.dns_name}:9000" },
        { name = "S3_BUCKET_NAME", value = "chatapp-uploads-bucket" },
        { name = "S3_ACCESS_KEY", value = "minioadmin" },
        { name = "S3_SECRET_KEY", value = "minioadminpassword" },
        { name = "AWS_REGION", value = "us-east-1" },

      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "backend"
        }
      }
      portMappings = [
        {
          containerPort = 8080
          hostPort = 8080
        }
      ]
      
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name = "backend-service"
  cluster  = aws_ecs_cluster.chatapp.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count = 1
  launch_type = "FARGATE"
  enable_execute_command = true
  network_configuration {
    subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_service.postgres, aws_ecs_service.minio]
  load_balancer {
        target_group_arn = aws_lb_target_group.backend.arn
        container_name = "backend"
        container_port = "8080"
    }
}