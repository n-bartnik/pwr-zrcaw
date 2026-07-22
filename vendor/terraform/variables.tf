
variable "lab_role" {
    description = "The role of the lab"
    type        = string
}

variable "db_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}
