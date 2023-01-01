#!/bin/bash

# This script runs on all k3 nodes at startup

ARCH=$(uname -m); if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi

# unzip + awscli install
dpkg -i "$PWD"/unzip-"$ARCH".deb
unzip -q -o awscli-exe-linux-"$ARCH".zip
./aws/install --bin-dir /usr/local/bin --install-dir /opt/awscli --update

# add'l vars
AWS_METADATA_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AWS_AZ=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_ECR_PREFIX="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$PREFIX-$SUFFIX"
CHARTS_PATH="/opt/charts"
INSTALL_K3S_SKIP_DOWNLOAD="true"
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_IP=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
K3S_TOKEN=$(/usr/local/bin/aws --region "$REGION" ssm get-parameter --with-decryption --name /"$PREFIX"-"$SUFFIX"/K3S_TOKEN --query Parameter.Value --output text)
K3S_BIN_PATH="/usr/local/bin"
K3S_BIN_FILE="k3s"
K3S_TAR_PATH="/var/lib/rancher/k3s/agent/images"
K3S_TAR_FILE="k3s-airgap-images"
K3S_INSTALL_PATH="/usr/local/bin"
K3S_INSTALL_FILE="install.sh"
K3S_URL="https://control-plane.$PREFIX-$SUFFIX.internal:6443"

# ensure SSM and above vars are exported
export ARCH AMI_TYPE AWS_ADDON_URI AWS_AZ AWS_ECR_PREFIX AWS_METADATA_TOKEN CHARTS_PATH EFS_ID INSTALL_K3S_SKIP_DOWNLOAD INSTANCE_ID INSTANCE_IP INSTANCE_TYPE K3S_BIN_FILE K3S_BIN_PATH K3S_INSTALL_FILE K3S_INSTALL_PATH K3S_NODEGROUP K3S_TAR_FILE K3S_TAR_PATH K3S_TOKEN K3S_URL KUBEDNS_IP NAT_GATEWAYS POD_CIDR PREFIX REGION SUFFIX SVC_CIDR VPC_CIDR

# copy scaledown.sh
cp scaledown.sh /usr/local/bin/scaledown.sh

# k3s directories
mkdir -p /etc/rancher/k3s /var/lib/rancher/k3s/agent/images /var/lib/rancher/k3s/agent/etc/containerd
chmod 750 /etc/rancher/k3s /var/lib/rancher/k3s/agent/images /var/lib/rancher/k3s/agent/etc/containerd

# ec2 vpc r53 nameserver to k3s
echo "nameserver 169.254.169.253" > /etc/rancher/k3s/resolv.conf

# ec2 ip to /etc/hosts https://github.com/k3s-io/k3s/issues/163#issuecomment-469882207
if grep --quiet "$INSTANCE_IP" /etc/hosts; then
    tee -a /etc/hosts << EOM

# k3s
$INSTANCE_IP localhost
$INSTANCE_IP $(hostname)

EOM
fi

# k3s binary
if [ -f "$K3S_BIN_PATH/$K3S_BIN_FILE" ]; then
    echo "bin exists, skipping"
else
    /usr/local/bin/aws --region "$REGION" s3 cp --quiet s3://"$PREFIX"-"$SUFFIX"-private/data/downloads/k3s/"$K3S_BIN_FILE"-"$ARCH" "$K3S_BIN_PATH"/"$K3S_BIN_FILE" --quiet
    chmod +x "$K3S_BIN_PATH"/"$K3S_BIN_FILE"
fi

# k3s tar
if [ -f "$K3S_TAR_PATH/$K3S_TAR_FILE".tar ]; then
    echo "tar exists, skipping"
else
    /usr/local/bin/aws --region "$REGION" s3 cp --quiet s3://"$PREFIX"-"$SUFFIX"-private/data/downloads/k3s/"$K3S_TAR_FILE"-"$ARCH".tar "$K3S_TAR_PATH"/"$K3S_TAR_FILE".tar --quiet
fi

# k3s install script
if [ -f "$K3S_INSTALL_PATH/$K3S_INSTALL_FILE" ]; then
    echo "script exists, skipping"
else
    mkdir -p "$K3S_INSTALL_PATH"
    cp ./install.sh "$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"
    chmod +x "$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"
fi

# gpu use nvidia runtime
if [ "$AMI_TYPE" != "gpu" ]; then
    echo "AMI_TYPE not gpu, skipping"
else
    cp ./cuda-config.toml.tmpl /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl
fi

# install k3s
if [ "$K3S_NODEGROUP" == "control-plane" ]; then
    bash control-plane.sh
else
    bash worker.sh
fi
