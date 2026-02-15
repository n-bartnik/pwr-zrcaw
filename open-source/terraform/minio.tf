resource "aws_ecs_task_definition" "minio" {
  family = "chatapp-minio"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "512"
  memory = "1024"

  execution_role_arn = var.lab_role
  task_role_arn = var.lab_role

  container_definitions = jsonencode([
    {
      name = "minio"
      image = "minio/minio:latest"
      essential = true

      command = ["server", "/data", "--console-address", ":9001"]

      portMappings = [
        { containerPort = 9000 },
        { containerPort = 9001 }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = aws_cloudwatch_log_group.minio.name
          "awslogs-region" = "us-east-1"
          "awslogs-stream-prefix" = "minio"
        }
      }

      environment = [
        { name = "MINIO_ROOT_USER", value = "minioadmin" },
        { name = "MINIO_ROOT_PASSWORD", value = "minioadminpassword" }
      ]

    }
  ])
}

resource "aws_ecs_service" "minio" {
  name            = "minio-service"
  cluster         = aws_ecs_cluster.chatapp.id
  task_definition = aws_ecs_task_definition.minio.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = true
  }
    load_balancer {
    target_group_arn = aws_lb_target_group.minio_api_tg.arn
    container_name = "minio"
    container_port = 9000
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.minio_console_tg.arn
    container_name = "minio"
    container_port = 9001
  }
}
