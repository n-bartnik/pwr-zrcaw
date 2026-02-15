
output "alb_dns_name" {
  value = aws_lb.chatapp.dns_name
}

output "keycloak_alb_dns_name" {
  value = aws_lb.keycloak.dns_name
}


output "keycloak_admin_url" {
  value = "https://${var.auth_domain}/admin"
  description = "Keycloak Admin Console URL"
}



output "keycloak_test_user" {
  value = "testuser / admin123"
  description = "Test user credentials"
}

output "keycloak_admin_realm_user" {
  value = "admin / admin123"
  description = "Admin user credentials for chatapp realm"
}

output "nlb_output" {
 value=  aws_lb.postgres_nlb.dns_name
}