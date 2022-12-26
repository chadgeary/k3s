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
cluster_cidr  = "172.17.0.0/16" # assigned to k3s pods and services
azs           = 2               # aws azs
nat_gateways  = true            # permits internet egress
vpc_endpoints = false           # required if nat_gateways = false, optional otherwise.

## Logs
# codebuild, lambda
log_retention_in_days = 30 # 0 = never expire

## URLs
# awscli @ https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# helm @ https://github.com/helm/helm/releases
# k3s @ https://github.com/k3s-io/k3s/releases
# cloud controller @ https://kubernetes.github.io/cloud-provider-aws/index.yaml
# ebs @ https://github.com/kubernetes-sigs/aws-ebs-csi-driver/releases
# efs @ https://github.com/kubernetes-sigs/aws-efs-csi-driver/releases
# cilium @ https://helm.cilium.io/index.yaml
# external-dns @ https://charts.bitnami.com/bitnami/index.yaml
# unzip @ http://us-east-1.ec2.ports.ubuntu.com/ubuntu-ports/pool/main/u/unzip/ & http://us-east-1.ec2.archive.ubuntu.com/ubuntu/pool/main/u/unzip/
urls = {
  AWSCLIV2_X86_64      = "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
  AWSCLIV2_ARM64       = "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
  HELM_ARM64           = "https://get.helm.sh/helm-v3.10.3-linux-arm64.tar.gz"
  HELM_X86_64          = "https://get.helm.sh/helm-v3.10.3-linux-amd64.tar.gz"
  K3S_INSTALL          = "https://raw.githubusercontent.com/k3s-io/k3s/master/install.sh"
  K3S_BIN_ARM64        = "https://github.com/k3s-io/k3s/releases/download/v1.25.4%2Bk3s1/k3s-arm64"
  K3S_BIN_X86_64       = "https://github.com/k3s-io/k3s/releases/download/v1.25.4%2Bk3s1/k3s"
  K3S_TAR_ARM64        = "https://github.com/k3s-io/k3s/releases/download/v1.25.4%2Bk3s1/k3s-airgap-images-arm64.tar"
  K3S_TAR_X86_64       = "https://github.com/k3s-io/k3s/releases/download/v1.25.4%2Bk3s1/k3s-airgap-images-amd64.tar"
  AWS_CLOUD_CONTROLLER = "https://github.com/kubernetes/cloud-provider-aws/releases/download/helm-chart-aws-cloud-controller-manager-0.0.7/aws-cloud-controller-manager-0.0.7.tgz"
  AWS_EBS_CSI_DRIVER   = "https://github.com/kubernetes-sigs/aws-ebs-csi-driver/releases/download/helm-chart-aws-ebs-csi-driver-2.13.0/aws-ebs-csi-driver-2.13.0.tgz"
  AWS_EFS_CSI_DRIVER   = "https://github.com/kubernetes-sigs/aws-efs-csi-driver/releases/download/helm-chart-aws-efs-csi-driver-2.3.5/aws-efs-csi-driver-2.3.5.tgz"
  CILIUM               = "https://helm.cilium.io/cilium-1.13.0-rc4.tgz"
  EXTERNAL_DNS         = "https://charts.bitnami.com/bitnami/external-dns-6.12.1.tgz"
  UNZIP_ARM64          = "http://us-east-1.ec2.ports.ubuntu.com/ubuntu-ports/pool/main/u/unzip/unzip_6.0-26ubuntu3.1_arm64.deb"
  UNZIP_X86_64         = "http://us-east-1.ec2.archive.ubuntu.com/ubuntu/pool/main/u/unzip/unzip_6.0-26ubuntu3.1_amd64.deb"
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
# Ubuntu 20.04 (will bump to 22.04 when a deep learning AMI is released)
# https://cloud-images.ubuntu.com/locator/ec2/
# https://docs.aws.amazon.com/dlami/latest/devguide/appendix-ami-release-notes.html
amis = {
  arm64  = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"
  x86_64 = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  gpu    = "AWS Deep Learning Base AMI GPU CUDA *(Ubuntu 20.04)*"
}

## Container Images
# Images cloned to Private ECR via codebuild
# ensure charts.sh tags match
container_images = [
  "amazon/aws-efs-csi-driver:v1.4.8",
  "registry.k8s.io/provider-aws/cloud-controller-manager:v1.25.1",
  "ghcr.io/zcube/bitnami-compat/external-dns:0",
  "k8s.gcr.io/sig-storage/csi-provisioner:v3.1.0",
  "k8s.gcr.io/sig-storage/csi-attacher:v3.4.0",
  "k8s.gcr.io/sig-storage/csi-snapshotter:v6.0.1",
  "k8s.gcr.io/sig-storage/livenessprobe:v2.6.0",
  "k8s.gcr.io/sig-storage/csi-resizer:v1.4.0",
  "k8s.gcr.io/sig-storage/csi-node-driver-registrar:v2.5.1"
]

## Node groups via ASGs
# one group must be named 'control-plane' with a min of 1
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
    instance_types = ["t4g.medium"]
  }
  generalpurpose1 = {
    ami = "x86_64"
    scaling_count = {
      min = 1
      max = 1
    }
    volume = {
      gb   = 100
      type = "gp3"
    }
    instance_types = ["t3a.medium", "t3.medium"]
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
