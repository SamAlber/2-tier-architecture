resource "aws_db_instance" "rds_instance" {
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = var.parameter_group_name
  publicly_accessible    = var.publicly_accessible
  vpc_security_group_ids = [var.db_security_group_id] # RDS uses the vpc_security_group_ids argument, which accepts a list!! of security group IDs.(RDS instances don't have a db_security_group_id argument)
  db_subnet_group_name   = var.db_subnet_group_name
  skip_final_snapshot    = var.skip_final_snapshot

  multi_az               = true # Enable Multi-AZ deployment

  tags = var.tags
}
