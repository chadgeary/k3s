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

## Secrets
# Encrypted SSM parameters, available to EC2 instances
# The path to each value is /${local.prefix}-${local.suffix}/<key>
# Warn: Keep this file and the terraform state file secure!
secrets = {
  K3S_TOKEN = "Change_me_please_1"
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
  "ghcr.io/zcube/bitnami-compat/external-dns:0"
]

## Node groups via ASGs
# one group must be named 'control-plane' with a min of 1
nodegroups = {
  control-plane = {
    ami = "arm64"
    scaling_count = {
      min = 2
      max = 2
    }
    volume = {
      gb   = 15
      type = "gp3"
    }
    instance_types = ["t4g.small", "a1.medium"]
  }
  generalpurpose1 = {
    ami = "x86_64"
    scaling_count = {
      min = 2
      max = 2
    }
    volume = {
      gb   = 15
      type = "gp3"
    }
    instance_types = ["t3a.medium", "t3.medium"]
  }
}

## lambda_to_s3
# each represents a lambda invocation for downloading a file to s3 (if not exists)
# awscli @ https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# helm @ https://github.com/helm/helm/releases
# k3s @ https://github.com/k3s-io/k3s/releases
# cloud controller @ https://kubernetes.github.io/cloud-provider-aws/index.yaml
# efs @ https://github.com/kubernetes-sigs/aws-efs-csi-driver/releases
# cilium @ https://helm.cilium.io/index.yaml
# external-dns @ https://charts.bitnami.com/bitnami/index.yaml
# unzip @ http://us-east-1.ec2.ports.ubuntu.com/ubuntu-ports/pool/main/u/unzip/ & http://us-east-1.ec2.archive.ubuntu.com/ubuntu/pool/main/u/unzip/
lambda_to_s3 = {
  AWSCLIV2_ARM64 = {
    url    = "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
    prefix = "scripts/awscli-exe-linux-arm64.zip"
  }
  AWSCLIV2_X86_64 = {
    url    = "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
    prefix = "scripts/awscli-exe-linux-x86_64.zip"
  }
  HELM_ARM64 = {
    url    = "https://get.helm.sh/helm-v3.10.3-linux-arm64.tar.gz"
    prefix = "data/downloads/k3s/helm-arm64.tar.gz"
  }
  HELM_X86_64 = {
    url    = "https://get.helm.sh/helm-v3.10.3-linux-amd64.tar.gz"
    prefix = "data/downloads/k3s/helm-x86_64.tar.gz"
  }
  K3S_BIN_ARM64 = {
    url    = "https://github.com/k3s-io/k3s/releases/download/v1.25.4%2Bk3s1/k3s-arm64"
    prefix = "data/downloads/k3s/k3s-arm64"
  }
  K3S_BIN_X86_64 = {
    url    = "https://github.com/k3s-io/k3s/releases/download/v1.25.4%2Bk3s1/k3s"
    prefix = "data/downloads/k3s/k3s-x86_64"
  }
  K3S_TAR_ARM64 = {
    url    = "https://github.com/k3s-io/k3s/releases/download/v1.25.4%2Bk3s1/k3s-airgap-images-arm64.tar"
    prefix = "data/downloads/k3s/k3s-airgap-images-arm64.tar"
  }
  K3S_TAR_X86_64 = {
    url    = "https://github.com/k3s-io/k3s/releases/download/v1.25.4%2Bk3s1/k3s-airgap-images-amd64.tar"
    prefix = "data/downloads/k3s/k3s-airgap-images-x86_64.tar"
  }
  K3S_INSTALL = {
    url    = "https://raw.githubusercontent.com/k3s-io/k3s/master/install.sh"
    prefix = "scripts/install.sh"
  }
  AWS_CLOUD_CONTROLLER = {
    url    = "https://github.com/kubernetes/cloud-provider-aws/releases/download/helm-chart-aws-cloud-controller-manager-0.0.7/aws-cloud-controller-manager-0.0.7.tgz"
    prefix = "data/downloads/charts/aws-cloud-controller-manager.tgz"
  }
  AWS_EFS_CSI_DRIVER = {
    url    = "https://github.com/kubernetes-sigs/aws-efs-csi-driver/releases/download/helm-chart-aws-efs-csi-driver-2.3.5/aws-efs-csi-driver-2.3.5.tgz"
    prefix = "data/downloads/charts/aws-efs-csi-driver.tgz"
  }
  CILIUM = {
    url    = "https://helm.cilium.io/cilium-1.13.0-rc4.tgz"
    prefix = "data/downloads/charts/cilium.tgz"
  }
  EXTERNAL_DNS = {
    url    = "https://charts.bitnami.com/bitnami/external-dns-6.12.1.tgz"
    prefix = "data/downloads/charts/external-dns.tgz"
  }
  UNZIP_ARM64 = {
    url    = "http://us-east-1.ec2.ports.ubuntu.com/ubuntu-ports/pool/main/u/unzip/unzip_6.0-26ubuntu3.1_arm64.deb"
    prefix = "scripts/unzip-arm64.deb"
  }
  UNZIP_X86_64 = {
    url    = "http://us-east-1.ec2.archive.ubuntu.com/ubuntu/pool/main/u/unzip/unzip_6.0-26ubuntu3.1_amd64.deb"
    prefix = "scripts/unzip-x86_64.deb"
  }
}
