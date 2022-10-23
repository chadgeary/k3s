## Project
# Labels attached to resource names, use a short lower alphanumeric string
# If suffix is empty, a random two character suffix is generated
prefix = "k3s"
suffix = "dev"

## AWS
aws_profile = "default"
aws_region  = "us-east-2"

## VPC
# vpc_cidr is split across availability zones, minimum 2
vpc_cidr = "172.16.0.0/16"
azs      = 2

## Logs
# lambda, ec2
log_retention_in_days = 30 # 0 = never expire

## URLs
# Where K3s is downloaded from (via lambda to s3 for ec2s to pickup offline)
urls = {
  k3s_bin-arm64  = "https://github.com/k3s-io/k3s/releases/download/v1.25.2%2Bk3s1/k3s-arm64"
  k3s_bin-x86_64 = "https://github.com/k3s-io/k3s/releases/download/v1.25.2%2Bk3s1/k3s"
  k3s_tar-arm64  = "https://github.com/k3s-io/k3s/releases/download/v1.25.2%2Bk3s1/k3s-airgap-images-arm64.tar"
  k3s_tar-x86_64 = "https://github.com/k3s-io/k3s/releases/download/v1.25.2%2Bk3s1/k3s-airgap-images-amd64.tar"
  k3s_install    = "https://raw.githubusercontent.com/k3s-io/k3s/master/install.sh"
}

## Secrets
# Encrypted SSM parameters, available to EC2 instances
# The path to each value is /${local.prefix}-${local.suffix}/<key>
# Warn: Keep this file and the terraform state file secure!
secrets = {
  K3S_TOKEN = "Change_me_please_1"
  DB_PASS   = "also_Change_me_2"
}

## AMIs
# The Amazon Linux AMI name string and account number.
# ARM equivalent instances cost less and are used by the control plane (and RDS)
# To find your region's AMI, replace us-east-1 with your region, then run the command:
# AWS_REGION=us-east-1 && aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-arm64-gp2 --region $AWS_REGION
# AWS_REGION=us-east-1 && aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region $AWS_REGION
# AWS_REGION=us-east-1 && aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended --region $AWS_REGION
amis = {
  arm64  = "amzn2-ami-hvm-*-arm64-gp2"
  x86_64 = "amzn2-ami-hvm-*-x86_64-gp2"
  gpu    = "amzn2-ami-ecs-gpu-hvm-*-x86_64-ebs"
}

## Container Images
# Images not available on Public ECR or Quay.io cloned to Private ECR via codebuild
container_images = [
  "k8s.gcr.io/autoscaling/cluster-autoscaler-arm64:v1.25.0",
  "k8s.gcr.io/autoscaling/cluster-autoscaler-amd64:v1.25.0"
]

## Node groups via asgs
# Instance types @ https://instances.vantage.sh/
# at least one group must be named 'master'
nodegroups = {
  master = {
    ami = "arm64"
    scaling_count = {
      min = 1
      max = 1
    }
    volume = {
      gb   = 20
      type = "gp3"
    }
    instance_types = ["t4g.micro"]
  }
  generalpurpose = {
    ami = "x86_64"
    scaling_count = {
      min = 1
      max = 1
    }
    volume = {
      gb   = 100
      type = "gp3"
    }
    instance_types = ["t3a.small", "t3.small"]
  }
  gpu = {
    ami = "gpu"
    scaling_count = {
      min = 0
      max = 0
    }
    volume = {
      gb   = 100
      type = "gp3"
    }
    instance_types = ["g4dn.xlarge"]
  }
}

# k3s datastore via rds
rds = {
  allocated_storage       = 5
  backup_retention_period = 0
  engine                  = "postgres"
  engine_version          = "14.3"
  instance_class          = "db.t4g.micro"
  storage_type            = "standard"
}
