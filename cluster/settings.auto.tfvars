## Project
# A label attached to resource names, use a short alphanumeric string
prefix = "k3"

## AWS
aws_profile = "default"
aws_region  = "us-east-2"

## URLs
# Where K3s is downloaded from (via lambda to s3 for ec2s to pickup offline)
urls = {
  k3s_bin-arm64  = "https://github.com/k3s-io/k3s/releases/download/v1.25.2%2Bk3s1/k3s-arm64"
  k3s_bin-x86_64 = "https://github.com/k3s-io/k3s/releases/download/v1.25.2%2Bk3s1/k3s"
  k3s_tar-arm64  = "https://github.com/k3s-io/k3s/releases/download/v1.25.2%2Bk3s1/k3s-airgap-images-arm64.tar"
  k3s_tar-x86_64 = "https://github.com/k3s-io/k3s/releases/download/v1.25.2%2Bk3s1/k3s-airgap-images-amd64.tar"
}

## Instances
# Instance types @ https://instances.vantage.sh/
instances = {
  master = {
    arch = "arm64"
    scaling_count = {
      min = 1
      max = 1
    }
    volume = {
      gb   = 20
      type = "gp3"
    }
    memory_mib = {
      min = 1024
      max = 1024
    }
    vcpu_count = {
      min = 2
      max = 2
    }
    burstable_performance = "included"
    local_storage         = "excluded"
  }
  worker = {
    arch = "x86_64"
    scaling_count = {
      min = 2
      max = 2
    }
    volume = {
      gb   = 100
      type = "gp3"
    }
    memory_mib = {
      min = 2048
      max = 2048
    }
    vcpu_count = {
      min = 2
      max = 2
    }
    burstable_performance = "included"
    local_storage         = "excluded"
  }
}

## Logs
log_retention_in_days = 1

## Secrets
# Stored encrypted in SSM Parameter Store, usable by instances
# The path to each value is /${local.prefix}-${local.suffix}/<key>
# Hint: pass PREFIX and SUFFIX with an SSM playbook
# Warn: Keep this terraform state file secure!
secrets = {
  K3S_TOKEN = "Change_me_please_1"
  DB_PASS   = "also_Change_me_2"
}

## AMI
# The Amazon Linux AMI name string and account number.
# ARM equivalent instances cost less and are used by the control plane (and RDS)
# To find your region's AMI, replace us-east-2 with your region, then run the command:
# AWS_REGION=us-east-2 && aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-arm64-gp2 --region $AWS_REGION
# AWS_REGION=us-east-2 && aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region $AWS_REGION
vendor_ami_name_string_arm64  = "amzn2-ami-hvm-*-arm64-gp2"
vendor_ami_name_string_x86_64 = "amzn2-ami-hvm-*-x86_64-gp2"


## VPC
# Subnet used by the VPC and split across the associated subnets
# The number of subnets is 2*(azs), one private and one public per az
# Because subnets are based on the assumption the vpc_cidr is a /20 and the subnets will be a /24, keep it a /20
# or edit locals.tf - especially the cidrsubnet() function
# private internal load balancer is .8
vpc_cidr = "172.16.0.0/20"
azs      = 2
