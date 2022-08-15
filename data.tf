## AWS Data
data "aws_availability_zones" "cloudk3s" {
  state = "available"
}

data "aws_caller_identity" "cloudk3s" {
}

data "aws_partition" "cloudk3s" {
}

## AMI
data "aws_ami" "cloudk3s" {
  most_recent = true
  owners      = [var.vendor_ami_account_number]
  filter {
    name   = "name"
    values = [var.vendor_ami_name_string]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["arm64", "x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
