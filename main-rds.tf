# db for k3s state
resource "aws_db_subnet_group" "cloudk3s" {
  name       = "${local.prefix}-${local.suffix}"
  subnet_ids = [for net in aws_subnet.cloudk3s-private : net.id]
  tags = {
    Name = "${local.prefix}-${local.suffix}"
  }
}

resource "aws_db_instance" "cloudk3s" {
  allocated_storage       = 1
  availability_zone       = data.aws_availability_zones.cloudk3s.names[0]
  engine                  = "postgres"
  engine_version          = "14.3"
  instance_class          = "db.t3.micro"
  db_name                 = "${local.prefix}${local.suffix}"
  username                = "${local.prefix}-${local.suffix}"
  password                = var.secrets.DB_PASS
  port                    = 5432
  publicly_accessible     = false
  backup_retention_period = 0
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.cloudk3s["rds"].arn
  skip_final_snapshot     = true
  storage_type            = "standard"
  db_subnet_group_name    = aws_db_subnet_group.cloudk3s.name
  vpc_security_group_ids  = [aws_security_group.cloudk3s-rds.id]
}
