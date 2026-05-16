resource "aws_db_subnet_group" "app_db_subnets" {
  name       = "${var.project_name}-app-db-subnet-group"
  subnet_ids = module.spoke_vpcs["app"].private_subnets

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-app-db-subnet-group"
  })
}

resource "aws_db_instance" "app_db" {
  identifier             = "${var.project_name}-app-db"
  allocated_storage      = var.db_allocated_storage
  engine                 = "mysql"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.app_db_subnets.name
  vpc_security_group_ids = [aws_security_group.app_db_sg.id]
  publicly_accessible    = false
  multi_az               = false # For production, consider setting multi_az = true
  skip_final_snapshot    = true  # For student environments to save credits

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-app-db"
  })

  depends_on = [aws_db_subnet_group.app_db_subnets]
}
