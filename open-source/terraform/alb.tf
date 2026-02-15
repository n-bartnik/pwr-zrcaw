

resource "aws_lb" "chatapp" {
  name = "chatapp-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.ecs.id]
  subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}


resource "aws_lb_target_group" "frontend" {
  name = "frontend-tg"
  port = 3000
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"
}

resource "aws_lb_target_group" "backend" {
  name = "backend-tg"
  port = 8080
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path = "/actuator/health"
    matcher  = "200-399"
    interval  = 60
    timeout = 10
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "backend_http" {
  load_balancer_arn = aws_lb.chatapp.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.chatapp.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = aws_acm_certificate.decard_cert.arn

  default_action {
    order = 1
    type = "authenticate-oidc"
    authenticate_oidc {
      issuer                              = "https://${var.auth_domain}/realms/chatapp"
      authorization_endpoint              = "https://${var.auth_domain}/realms/chatapp/protocol/openid-connect/auth"
      token_endpoint                      = "https://${var.auth_domain}/realms/chatapp/protocol/openid-connect/token"
      user_info_endpoint                  = "https://${var.auth_domain}/realms/chatapp/protocol/openid-connect/userinfo"
      client_id                           = "chatapp-client"
      client_secret                       = "uaqjsQH68iBc5l6rFeq1RaBW8FVetyh7"
      session_cookie_name                 = "AWSELBAuthSessionCookie"
      scope                               = "openid email"
      on_unauthenticated_request          = "authenticate"
    }
  }

  default_action {
    order = 2
    type = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority = 11

  action {
    type = "authenticate-oidc"
    authenticate_oidc {
      issuer                              = "https://${var.auth_domain}/realms/chatapp"
      authorization_endpoint              = "https://${var.auth_domain}/realms/chatapp/protocol/openid-connect/auth"
      token_endpoint                      = "https://${var.auth_domain}/realms/chatapp/protocol/openid-connect/token"
      user_info_endpoint                  = "https://${var.auth_domain}/realms/chatapp/protocol/openid-connect/userinfo"
      client_id                           = "chatapp-client"
      client_secret                       = "uaqjsQH68iBc5l6rFeq1RaBW8FVetyh7"
      session_cookie_name                 = "AWSELBAuthSessionCookie"
      scope                               = "openid email"
      on_unauthenticated_request          = "authenticate"
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/chat*", "/chat/*"]
    }
  }
}


resource "aws_lb" "keycloak" {
  name = "keycloak-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.ecs.id]
  subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}


resource "aws_lb_target_group" "keycloak" {
  name        = "keycloak-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path = "/health/ready"
    matcher = "200"
    interval = 60
    timeout = 10
    healthy_threshold = 2
    unhealthy_threshold = 5
  }

  deregistration_delay = 30
}

resource "aws_lb_listener" "keycloak_https" {
  load_balancer_arn = aws_lb.keycloak.arn
  port              = 443
  protocol          = "HTTPS"
  
  certificate_arn   = aws_acm_certificate.decard_cert.arn 

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keycloak.arn
  }
}
