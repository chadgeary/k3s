## AWS Data
data "aws_availability_zones" "cloudk3s" {
  state = "available"
}

data "aws_caller_identity" "cloudk3s" {
}

data "aws_partition" "cloudk3s" {
}

## AMIs
data "aws_ami" "cloudk3s" {
  for_each    = var.amis
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = [each.value]
  }
}
