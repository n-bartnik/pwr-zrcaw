
variable "lab_role" {
    description = "The role of the lab"
    type = string
    default = "arn:aws:iam::336497654287:role/LabRole"
}
variable "auth_domain" {
  description = "Domain for Keycloak authentication (e.g., auth.example.com)"
  type = string
}
variable "app_domain" {
  description = "Domain for the application (e.g. app.example.com) for redirect URIs"
  type = string
}