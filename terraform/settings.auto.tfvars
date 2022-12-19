## Project
# Labels attached to resource names, use a short lower alphanumeric string
# If suffix is empty, a random two character suffix is generated
prefix = "k3s"
suffix = ""

## AWS
profile = "default"
region  = "us-east-1"

## Networking
vpc_cidr      = "172.16.0.0/16" # vpc_cidr is split across availability zones, minimum 2
pod_cidr      = "172.17.0.0/16" # assigned to pods
azs           = 2               # aws azs
nat_gateways  = true            # permits internet egress
vpc_endpoints = false           # required if nat_gateways = false, optional otherwise.

## Logs
# codebuild, lambda
log_retention_in_days = 30 # 0 = never expire

## URLs
# helm @ https://github.com/helm/helm/releases
# k3s @ https://github.com/k3s-io/k3s/releases
# cloud controller @ https://kubernetes.github.io/cloud-provider-aws/index.yaml
# calico @ https://projectcalico.docs.tigera.io/charts/index.yaml
# external-dns @ https://charts.bitnami.com/bitnami/index.yaml
urls = {
  HELM_ARM64           = "https://get.helm.sh/helm-v3.10.3-linux-arm64.tar.gz"
  HELM_X86_64          = "https://get.helm.sh/helm-v3.10.3-linux-amd64.tar.gz"
  K3S_INSTALL          = "https://raw.githubusercontent.com/k3s-io/k3s/master/install.sh"
  K3S_BIN_ARM64        = "https://github.com/k3s-io/k3s/releases/download/v1.25.4%2Bk3s1/k3s-arm64"
  K3S_BIN_X86_64       = "https://github.com/k3s-io/k3s/releases/download/v1.25.4%2Bk3s1/k3s"
  K3S_TAR_ARM64        = "https://github.com/k3s-io/k3s/releases/download/v1.25.4%2Bk3s1/k3s-airgap-images-arm64.tar"
  K3S_TAR_X86_64       = "https://github.com/k3s-io/k3s/releases/download/v1.25.4%2Bk3s1/k3s-airgap-images-amd64.tar"
  AWS_CLOUD_CONTROLLER = "https://github.com/kubernetes/cloud-provider-aws/releases/download/helm-chart-aws-cloud-controller-manager-0.0.7/aws-cloud-controller-manager-0.0.7.tgz"
  CALICO               = "https://github.com/projectcalico/calico/releases/download/v3.24.5/tigera-operator-v3.24.5.tgz"
  EXTERNAL_DNS         = "https://charts.bitnami.com/bitnami/external-dns-6.12.1.tgz"
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
# ARM equivalent instances cost less and may be used by the control plane (and RDS)
# To find your region's AMI, replace us-east-1 with your region, then run the command:
# REGION=us-east-1 && aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-arm64-gp2 --region $REGION
# REGION=us-east-1 && aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region $REGION
# REGION=us-east-1 && aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended --region $REGION
amis = {
  arm64  = "amzn2-ami-hvm-*-arm64-gp2"
  x86_64 = "amzn2-ami-hvm-*-x86_64-gp2"
  gpu    = "amzn2-ami-ecs-gpu-hvm-*-x86_64-ebs"
}

## Container Images
# Images cloned to Private ECR via codebuild
container_images = {
  arm64 = [
    "amazon/aws-cli:arm64",
    "registry.k8s.io/provider-aws/cloud-controller-manager:v1.25.1", # ensure scripts/charts.sh ref is up-to-date
    "ghcr.io/zcube/bitnami-compat/external-dns:0"
  ]
  x86_64 = [
    "amazon/aws-cli:amd64",
    "registry.k8s.io/provider-aws/cloud-controller-manager:v1.25.1", # ensure scripts/charts.sh ref is up-to-date
    "ghcr.io/zcube/bitnami-compat/external-dns:0"
  ]
}

## Node groups via ASGs
# one group must be named 'control-plane'
nodegroups = {
  control-plane = {
    ami = "arm64"
    scaling_count = {
      min = 1
      max = 1
    }
    volume = {
      gb   = 20
      type = "gp3"
    }
    instance_types = ["t4g.small"]
  }
  generalpurpose1 = {
    ami = "x86_64"
    scaling_count = {
      min = 0
      max = 0
    }
    volume = {
      gb   = 100
      type = "gp3"
    }
    instance_types = ["t3a.medium", "t3.medium"]
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


