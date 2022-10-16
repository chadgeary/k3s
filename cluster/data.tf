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

## k3s' install.sh
data "http" "k3s-install-sh" {
  url = "https://raw.githubusercontent.com/k3s-io/k3s/master/install.sh"

  request_headers = {
    Accept = "text/plain"
  }
}