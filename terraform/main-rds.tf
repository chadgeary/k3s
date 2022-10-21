# db for k3s state
resource "aws_db_subnet_group" "k3s" {
  name       = "${local.prefix}-${local.suffix}"
  subnet_ids = [for net in aws_subnet.k3s-private : net.id]
  tags = {
    Name = "${local.prefix}-${local.suffix}"
  }
}

resource "aws_db_instance" "k3s" {
  availability_zone       = data.aws_availability_zones.k3s.names[0]
  db_subnet_group_name    = aws_db_subnet_group.k3s.name
  vpc_security_group_ids  = [aws_security_group.k3s-rds.id]
  multi_az                = false
  allocated_storage       = var.rds.allocated_storage
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
  kms_key_id              = aws_kms_key.k3s["rds"].arn
  skip_final_snapshot     = true
  storage_type            = var.rds.storage_type

  tags = {
    Name = "${local.prefix}-${local.suffix}"
  }
}
