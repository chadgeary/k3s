#!/bin/bash

# This script runs on all k3 nodes at startup

ARCH=$(uname -m); if [ $ARCH = "aarch64" ]; then ARCH="arm64"; fi

# unzip + awscli install
dpkg -i $PWD/unzip-$ARCH.deb
unzip -o awscli-exe-linux-$ARCH.zip
./aws/install --bin-dir /usr/local/bin --install-dir /opt/awscli --update

# add'l vars
AWS_METADATA_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AZ=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
DB_PASS=$(/usr/local/bin/aws --region "$REGION" ssm get-parameter --with-decryption --name /"$PREFIX"-"$SUFFIX"/DB_PASS --query Parameter.Value --output text)
ECR_URI_PREFIX="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$PREFIX-$SUFFIX"
K3S_TOKEN=$(/usr/local/bin/aws --region "$REGION" ssm get-parameter --with-decryption --name /"$PREFIX"-"$SUFFIX"/K3S_TOKEN --query Parameter.Value --output text)
K3S_BIN_PATH="/usr/local/bin"
K3S_BIN_FILE="k3s"
K3S_TAR_PATH="/var/lib/rancher/k3s/agent/images"
K3S_TAR_FILE="k3s-airgap-images"
K3S_INSTALL_PATH="/usr/local/bin"
K3S_INSTALL_FILE="install.sh"
HELM_BIN_FILE="helm"
CHARTS_PATH="/opt/charts"
K3S_DATASTORE_ENDPOINT="postgres://$PREFIX$SUFFIX:$DB_PASS@$DB_ENDPOINT/$PREFIX$SUFFIX"
INSTALL_K3S_SKIP_DOWNLOAD="true"

export ARCH AWS_METADATA_TOKEN AWS_ADDON_URI AZ EBS_KMS_ARN EFS_ID ECR_URI_PREFIX DB_PASS INSTANCE_ID INSTANCE_TYPE K3S_LB K3S_TOKEN K3S_BIN_PATH K3S_BIN_FILE K3S_TAR_PATH K3S_TAR_FILE K3S_INSTALL_PATH K3S_INSTALL_FILE K3S_DATASTORE_ENDPOINT INSTALL_K3S_SKIP_DOWNLOAD HELM_BIN_FILE CHARTS_PATH POD_CIDR SVC_CIDR KUBEDNS_IP NAT_GATEWAYS VPC VPC_CIDR

# copy scaledown.sh
cp scaledown.sh /usr/local/bin/scaledown.sh

# k3s binary
if [ -f "$K3S_BIN_PATH/$K3S_BIN_FILE" ]; then
    echo "bin exists, skipping"
else
    /usr/local/bin/aws --region "$REGION" s3 cp s3://"$PREFIX"-"$SUFFIX"-private/data/downloads/k3s/"$K3S_BIN_FILE"-"$ARCH" "$K3S_BIN_PATH"/"$K3S_BIN_FILE"
    chmod +x "$K3S_BIN_PATH"/"$K3S_BIN_FILE"
fi

# k3s directories
mkdir -p /etc/rancher/k3s /var/lib/rancher/k3s/agent/images
chmod 750 /etc/rancher/k3s /var/lib/rancher/k3s/agent/images

# ec2 vpc r53 nameserver to k3s
echo "nameserver 169.254.169.253" > /etc/rancher/k3s/resolv.conf

# k3s tar
if [ -f "$K3S_TAR_PATH/$K3S_TAR_FILE".tar ]; then
    echo "tar exists, skipping"
else
    /usr/local/bin/aws --region "$REGION" s3 cp s3://"$PREFIX"-"$SUFFIX"-private/data/downloads/k3s/"$K3S_TAR_FILE"-"$ARCH".tar "$K3S_TAR_PATH"/"$K3S_TAR_FILE".tar --quiet
fi

# k3s install
if [ -f "$K3S_INSTALL_PATH/$K3S_INSTALL_FILE" ]; then
    echo "bin exists, skipping"
else
    /usr/local/bin/aws --region "$REGION" s3 cp s3://"$PREFIX"-"$SUFFIX"-private/scripts/"$K3S_INSTALL_FILE" "$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE" --quiet
    chmod +x "$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"
fi

# install k3s
if [ "$K3S_NODEGROUP" == "control-plane" ]; then
    bash control-plane.sh
else
    bash worker.sh
fi
