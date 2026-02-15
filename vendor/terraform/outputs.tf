output "chatapp_certificate_arn" {
  value = aws_acm_certificate.chatapp_cert.arn
}
output "bucket_name" {
  value = aws_s3_bucket.chat_uploads.id
}
output "alb_dns_name" {
  value = aws_lb.chatapp.dns_name
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.chatapp_user_pool.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.chatapp_client.id
}


output "cognito_domain" {
  value = aws_cognito_user_pool_domain.chatapp_domain.domain
}

output "cognito_user_pool_client_secret" {
  value = aws_cognito_user_pool_client.chatapp_client.client_secret
  sensitive = true
}

output "db_endpoint" {
  value = aws_db_instance.chatapp.endpoint
}
