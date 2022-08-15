## Project
# A label attached to resource names, stick with a short alphanumeric string
prefix = "k3s"

## AWS
aws_profile = "default"
aws_region  = "us-east-2"

## URLs
# Where K3s is downloaded from (via lambda to s3 for ec2s to pickup offline)
urls = {
  k3s_bin = "https://github.com/k3s-io/k3s/releases/download/v1.24.3%2Bk3s1/k3s"
  k3s_tar = "https://github.com/k3s-io/k3s/releases/download/v1.24.3%2Bk3s1/k3s-airgap-images-amd64.tar"
}

## Instances
# Instance types @ https://instances.vantage.sh/
# For k3s, use an odd number
instances = {
  scaling_count = {
    min = "1"
    max = "1"
  }
  volume = {
    gb   = "20"
    type = "gp3"
  }
  memory_mib = {
    min = "2048"
    max = "2048"
  }
  vcpu_count = {
    min = "2"
    max = "2"
  }
  burstable_performance = "included"
  local_storage         = "excluded"
  generations           = ["current"]
  log_retention_in_days = 1
}

## Secrets
# Stored encrypted in SSM Parameter Store, usable by instances
# The path to each value is /${local.prefix}-${local.suffix}/<key>
# Hint: pass PREFIX and SUFFIX with an SSM playbook
# Warn: Keep this terraform state file secure!
secrets = {
  K3S_TOKEN = "change_me_please!"
  DB_PASS   = "also_change_me!"
}

## AMI
# The (Ubuntu) AMI name string and account number.
# To find your region's AMI, replace us-east-1 with your region, then run the command:

# For ARM:
# AWS_REGION=us-east-1 && aws ec2 describe-images --region $AWS_REGION --owners 099720109477 --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*' 'Name=state,Values=available' --query 'sort_by(Images, &CreationDate)[-1].Name'

# For x86_64 (non-ARM):
# AWS_REGION=us-east-1 && aws ec2 describe-images --region $AWS_REGION --owners 099720109477 --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*' 'Name=state,Values=available' --query 'sort_by(Images, &CreationDate)[-1].Name'

vendor_ami_name_string    = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
vendor_ami_account_number = "099720109477"

## VPC
# Subnet used by the VPC and split across the associated subnets
# The number of subnets is 2*(azs), one private and one public per az
# Because subnets are based on the assumption the vpc_cidr is a /20 and the subnets will be a /24, keep it a /20
# or edit locals.tf - especially the cidrsubnet() function
# private internal load balancer is .8
vpc_cidr = "172.16.0.0/20"
azs      = 2
