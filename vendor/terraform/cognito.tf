

resource "aws_cognito_user_pool" "chatapp_user_pool" {
  name = "chatapp-userpool"

  auto_verified_attributes = ["email"]

  alias_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  schema {
    attribute_data_type      = "String"
    name                     = "email"
    required                 = true
    mutable                  = true
    developer_only_attribute = false
  }

}


resource "aws_cognito_user_pool_client" "chatapp_client" {
  name  = "chatapp_client"
  user_pool_id = aws_cognito_user_pool.chatapp_user_pool.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  generate_secret = true
  allowed_oauth_flows_user_pool_client = true

  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email","openid"]
  
  supported_identity_providers = ["COGNITO"]
  callback_urls = [
    "https://${aws_lb.chatapp.dns_name}/oauth2/idpresponse",
  ]
  logout_urls = ["https://${aws_lb.chatapp.dns_name}/"]
}

resource "aws_cognito_user_pool_domain" "chatapp_domain" {
  domain = "chatapp-${random_string.suffix.result}"
  user_pool_id = aws_cognito_user_pool.chatapp_user_pool.id
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_cognito_user" "test_user" {
  user_pool_id = aws_cognito_user_pool.chatapp_user_pool.id
  username     = "testuser"
  attributes = {
    preferred_username = "testuser"
    email = "testuser@example.com"
    email_verified = "true"
  }
  temporary_password = "Secret123!"
}
