resource "aws_cloudwatch_log_group" "backend" {
  name = "/ecs/chatapp-backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "frontend" {
  name = "/ecs/chatapp-frontend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "prometheus" {
  name = "/ecs/chatapp-prometheus"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "minio" {
  name = "/ecs/chatapp-minio"
  retention_in_days = 7
}