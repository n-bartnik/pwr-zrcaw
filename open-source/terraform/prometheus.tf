locals {
  prometheus_conf = <<-YAML
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: "spring-backend"
        metrics_path: "/actuator/prometheus"
        static_configs:
          - targets: ["${aws_lb.chatapp.dns_name}:8080"]
  YAML
}

resource "aws_ecs_task_definition" "prometheus" {
  family = "prometheus"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"
  execution_role_arn = var.lab_role
  task_role_arn = var.lab_role

  container_definitions = jsonencode([{
    name  = "prometheus"
    image = "prom/prometheus:latest"
    
    entryPoint = ["sh", "-c"]

    environment = [
      { 
        name  = "PROMETHEUS_CONFIG_B64", 
        value = base64encode(local.prometheus_conf) 
      }
    ]

    command = [
      "echo $PROMETHEUS_CONFIG_B64 | base64 -d > /tmp/prometheus.yml && /bin/prometheus --config.file=/tmp/prometheus.yml --storage.tsdb.path=/tmp/prometheus_data --storage.tsdb.no-lockfile"
    ]

    portMappings = [{ containerPort = 9090 }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group = "/ecs/chatapp-prometheus"
        awslogs-region = "us-east-1"
        awslogs-stream-prefix = "prometheus"
      }
    }
  }])
}

resource "aws_ecs_service" "prometheus" {
  name = "prometheus-service"
  cluster = aws_ecs_cluster.chatapp.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prometheus_tg.arn
    container_name = "prometheus"
    container_port = 9090
  }
}