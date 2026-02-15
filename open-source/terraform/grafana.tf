resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.lab_role
  task_role_arn            = var.lab_role

  container_definitions = jsonencode([{
    name  = "grafana"
    image = "${aws_ecr_repository.grafana.repository_url}:latest"
    portMappings = [{ containerPort = 3030 }]
    environment = [
      { name = "GF_SECURITY_ADMIN_PASSWORD", value = "admin123" },
      { name = "GF_SERVER_HTTP_PORT", value = "3030" },
      { name = "PROMETHEUS_URL", value = "http://${aws_lb.postgres_nlb.dns_name}:9090" }
    ]
  }])
}

resource "aws_ecs_service" "grafana" {
  name = "grafana-service"
  cluster = aws_ecs_cluster.chatapp.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana_tg.arn
    container_name = "grafana"
    container_port = 3030
  }
}
