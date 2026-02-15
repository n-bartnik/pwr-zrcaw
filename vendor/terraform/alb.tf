

resource "aws_lb" "chatapp" {
  name               = "chatapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}


resource "aws_lb_target_group" "frontend" {
  name     = "frontend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"
}

resource "aws_lb_target_group" "backend" {
  name     = "backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/actuator/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.chatapp.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.chatapp_cert.arn

 default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "frontend_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority = 21

    action {
    type = "authenticate-cognito"
    authenticate_cognito {
      user_pool_arn = aws_cognito_user_pool.chatapp_user_pool.arn
      user_pool_client_id = aws_cognito_user_pool_client.chatapp_client.id
      user_pool_domain = aws_cognito_user_pool_domain.chatapp_domain.domain
      session_cookie_name = "AWSELBAuthSessionCookie"
      scope = "openid email"
      on_unauthenticated_request = "authenticate"
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
  condition {
    path_pattern {
      values = ["/", "/*"]
    }
  }
}

resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority = 11
  action {
    type = "authenticate-cognito"
    authenticate_cognito {
      user_pool_arn = aws_cognito_user_pool.chatapp_user_pool.arn
      user_pool_client_id = aws_cognito_user_pool_client.chatapp_client.id
      user_pool_domain = aws_cognito_user_pool_domain.chatapp_domain.domain
      session_cookie_name = "AWSELBAuthSessionCookie"
      scope = "openid email"
      on_unauthenticated_request = "authenticate"
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
