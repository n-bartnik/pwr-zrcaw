resource "aws_ecs_task_definition" "postgres" {
  family                   = "chatapp-postgres"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"

  execution_role_arn = var.lab_role
  task_role_arn = var.lab_role

  container_definitions = jsonencode([
    {
      name      = "postgres"
      image     = "postgres:16"
      essential = true

      portMappings = [
        {
          containerPort = 5432
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "POSTGRES_DB", value = "chatdb" },
        { name = "POSTGRES_USER", value = "chatappuser" },
        { name = "POSTGRES_PASSWORD", value = "cPB6DnvyixTWJxif" },
        { name = "POSTGRES_MAX_CONNECTIONS", value = "100" },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/chatapp-postgres"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "postgres"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "postgres" {
  name              = "/ecs/chatapp-postgres"
  retention_in_days = 7
}

resource "aws_ecs_service" "postgres" {
  name            = "postgres-service"
  cluster         = aws_ecs_cluster.chatapp.id
  task_definition = aws_ecs_task_definition.postgres.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = true
  }
  depends_on = []
  
  load_balancer {
    target_group_arn = aws_lb_target_group.postgres_tg.arn
    container_name   = "postgres" 
    container_port   = 5432
  }
}



