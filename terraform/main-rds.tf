# db for k3s state
resource "aws_db_subnet_group" "cloudk3s" {
  name       = "${local.prefix}-${local.suffix}"
  subnet_ids = [for net in aws_subnet.cloudk3s-private : net.id]
  tags = {
    Name = "${local.prefix}-${local.suffix}"
  }
}

resource "aws_db_instance" "cloudk3s" {
  allocated_storage       = var.rds.allocated_storage
  availability_zone       = data.aws_availability_zones.cloudk3s.names[0]
  engine                  = var.rds.engine
  engine_version          = var.rds.engine_version
  instance_class          = var.rds.instance_class
  db_name                 = "${local.prefix}${local.suffix}"
  username                = "${local.prefix}${local.suffix}"
  password                = var.secrets.DB_PASS
  port                    = 5432
  publicly_accessible     = false
  backup_retention_period = var.rds.backup_retention_period
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.cloudk3s["rds"].arn
  skip_final_snapshot     = true
  storage_type            = var.rds.storage_type
  db_subnet_group_name    = aws_db_subnet_group.cloudk3s.name
  vpc_security_group_ids  = [aws_security_group.cloudk3s-rds.id]
}
