
resource "aws_db_instance" "chatapp" {
  identifier              = "chatapp-db"
  engine                  = "postgres"
  engine_version          = "16"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "chatdb"
  username                = "chatappuser"
  password                = var.db_password
  publicly_accessible     = true
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_db_subnet_group.chatapp.name
  vpc_security_group_ids  = [aws_security_group.ecs.id]
}
