
resource "docker_image" "frontend" {
  name = "${aws_ecr_repository.frontend.repository_url}:latest"
  build {
    context = "${path.cwd}/../cloud_frontend"
    dockerfile = "Dockerfile"
  }
}


resource "aws_ecs_task_definition" "frontend" {
  family = "chatapp-frontend"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"
  execution_role_arn = var.lab_role
  task_role_arn = var.lab_role

  container_definitions = jsonencode([
    {
      name = "frontend"
      image = "${aws_ecr_repository.frontend.repository_url}:latest"
      essential = true
      portMappings = [
        { containerPort = 3000, hostPort = 3000 }
      ]
      environment = [
        {
          name  = "PUBLIC_API_BASE_URL"
          value = "https://${var.app_domain}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "frontend"
        }
      }
     
    }
  ])
}

resource "aws_ecs_service" "frontend" {
  name = "frontend-service"
  cluster = aws_ecs_cluster.chatapp.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count = 1
  launch_type = "FARGATE"
  enable_execute_command = true
  network_configuration {
    subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = true
  }
  depends_on = []
  load_balancer {
        target_group_arn = aws_lb_target_group.frontend.arn
        container_name = "frontend"
        container_port = "3000"
    }
}