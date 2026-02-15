resource "aws_lb" "postgres_nlb" {
  name = "postgres-nlb"
  internal = false
  load_balancer_type = "network"
  subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id] 
}

resource "aws_lb_target_group" "postgres_tg" {
  name = "postgres-tg"
  port = 5432
  protocol = "TCP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"
  preserve_client_ip = "false"
  health_check {
    protocol = "TCP"
    interval = 30
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
  
  deregistration_delay = 30
}

resource "aws_lb_listener" "postgres_listener" {
  load_balancer_arn = aws_lb.postgres_nlb.arn
  port = 5432
  protocol = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.postgres_tg.arn
  }
}
resource "aws_lb_target_group" "minio_api_tg" {
  name = "minio-api-tg"
  port = 9000
  protocol = "TCP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"
  preserve_client_ip = "false" // MinIO wysyła odp do NLB, a nie do backendu

  health_check {
    protocol = "TCP"
    interval = 30
  }
}

resource "aws_lb_listener" "minio_api_listener" {
  load_balancer_arn = aws_lb.postgres_nlb.arn 
  port = 9000
  protocol = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.minio_api_tg.arn
  }
}

resource "aws_lb_target_group" "minio_console_tg" {
  name = "minio-console-tg"
  port = 9001
  protocol = "TCP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"
}

resource "aws_lb_listener" "minio_console_listener" {
  load_balancer_arn = aws_lb.postgres_nlb.arn
  port = 9001
  protocol = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.minio_console_tg.arn
  }
}


resource "aws_lb_target_group" "prometheus_tg" {
  name = "prometheus-tg"
  port = 9090
  protocol = "TCP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"
  preserve_client_ip = "false"
}

resource "aws_lb_listener" "prometheus_listener" {
  load_balancer_arn = aws_lb.postgres_nlb.arn
  port              = 9090
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus_tg.arn
  }
}

resource "aws_lb_target_group" "grafana_tg" {
  name = "grafana-tg"
  port = 3030
  protocol = "TCP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"
  preserve_client_ip = "false"
}

resource "aws_lb_listener" "grafana_listener" {
  load_balancer_arn = aws_lb.postgres_nlb.arn
  port = 3030
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }
}