## AWS Data
data "aws_availability_zones" "k3s" {
  state = "available"
}

data "aws_caller_identity" "k3s" {
}

data "aws_partition" "k3s" {
}

## AMIs
data "aws_ami" "k3s" {
  for_each    = var.amis
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = [each.value]
  }
}
