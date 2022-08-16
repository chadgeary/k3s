## Project
# A label attached to resource names, stick with a short alphanumeric string
prefix = "k3"

## AWS
aws_profile = "default"
aws_region  = "us-east-1"

## URLs
# Where K3s is downloaded from (via lambda to s3 for ec2s to pickup offline)
urls = {
  k3s_bin = "https://github.com/k3s-io/k3s/releases/download/v1.24.3%2Bk3s1/k3s"
  k3s_tar = "https://github.com/k3s-io/k3s/releases/download/v1.24.3%2Bk3s1/k3s-airgap-images-amd64.tar"
}

## Instances
# Instance types @ https://instances.vantage.sh/
instances = {
  master = {
    scaling_count = {
      min = 2
      max = 2
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
    generations           = ["current"]
  }
  worker = {
    scaling_count = {
      min = 2
      max = 2
    }
    volume = {
      gb   = 20
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
    generations           = ["current"]
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
# To find your region's AMI, replace us-east-1 with your region, then run the command:
# AWS_REGION=us-east-1 && aws ec2 describe-images --region $AWS_REGION --owners 099720109477 --filters 'Name=name,Values=amzn2-ami-hvm-*-x86_64-ebs' 'Name=state,Values=available' --query 'sort_by(Images, &CreationDate)[-1].Name'
vendor_ami_name_string = "amzn2-ami-hvm-*-x86_64-ebs"

## VPC
# Subnet used by the VPC and split across the associated subnets
# The number of subnets is 2*(azs), one private and one public per az
# Because subnets are based on the assumption the vpc_cidr is a /20 and the subnets will be a /24, keep it a /20
# or edit locals.tf - especially the cidrsubnet() function
# private internal load balancer is .8
vpc_cidr = "172.16.0.0/20"
azs      = 2
