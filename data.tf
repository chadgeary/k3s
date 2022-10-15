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
  owners      = ["amazon"]
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
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

## k3s' install.sh
data "http" "k3s-install-sh" {
  url = "https://raw.githubusercontent.com/k3s-io/k3s/master/install.sh"

  request_headers = {
    Accept = "text/plain"
  }
}