#!/bin/bash

ARCH=$(uname -m)
DB_PASS=$(aws ssm get-parameter --region "$AWS_REGION" --with-decryption --name /"$PREFIX"-"$SUFFIX"/DB_PASS --query Parameter.Value --output text)
K3S_TOKEN=$(aws ssm get-parameter --region "$AWS_REGION" --with-decryption --name /"$PREFIX"-"$SUFFIX"/K3S_TOKEN --query Parameter.Value --output text)
K3S_BIN_PATH="/usr/local/bin"
K3S_BIN_FILE="k3s"
K3S_TAR_PATH="/var/lib/rancher/k3s/agent/images"
K3S_TAR_FILE="k3s-airgap-images"
K3S_INSTALL_PATH="/usr/local/bin"
K3S_INSTALL_FILE="install.sh"
K3S_DATASTORE_ENDPOINT="postgres://$PREFIX$SUFFIX:$DB_PASS@$DB_ENDPOINT/$PREFIX$SUFFIX"
INSTALL_K3S_SKIP_DOWNLOAD="true"
export ARCH DB_PASS K3S_TOKEN K3S_BIN_PATH K3S_BIN_FILE K3S_TAR_PATH K3S_TAR_FILE K3S_INSTALL_PATH K3S_INSTALL_FILE K3S_DATASTORE_ENDPOINT INSTALL_K3S_SKIP_DOWNLOAD

# k3s binary
if [ -f "$K3S_BIN_PATH/$K3S_BIN_FILE" ]; then
    echo "bin exists, skipping"
else
    aws s3 cp s3://"$PREFIX"-"$SUFFIX"/data/downloads/k3s/"$K3S_BIN_FILE"-"$ARCH" "$K3S_BIN_PATH"/"$K3S_BIN_FILE"
    chmod +x "$K3S_BIN_PATH"/"$K3S_BIN_FILE"
fi

# k3s directories
mkdir -p /etc/rancher/k3s /var/lib/rancher/k3s/agent/images
chmod 750 /etc/rancher/k3s /var/lib/rancher/k3s/agent/images

# k3s tar
if [ -f "$K3S_TAR_PATH/$K3S_TAR_FILE".tar ]; then
    echo "tar exists, skipping"
else
    aws s3 cp s3://"$PREFIX"-"$SUFFIX"/data/downloads/k3s/"$K3S_TAR_FILE"-"$ARCH".tar "$K3S_TAR_PATH"/"$K3S_TAR_FILE".tar
fi

# k3s install
if [ -f "$K3S_INSTALL_PATH/$K3S_INSTALL_FILE" ]; then
    echo "bin exists, skipping"
else
    aws s3 cp s3://"$PREFIX"-"$SUFFIX"/scripts/"$K3S_INSTALL_FILE" "$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"
    chmod +x "$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"
fi

# k3s install exec
if [ "$K3S_NODEGROUP" == "master" ]; then
    echo "running installer (master/server)"
    INSTALL_K3S_EXEC="server"
    export INSTALL_K3S_EXEC
    "$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"

    echo "copying kube config to s3"
    for i in {1..120}; do
        echo -n "."
        aws s3 cp /etc/rancher/k3s/k3s.yaml s3://"$PREFIX"-"$SUFFIX"/data/k3s/config && echo "" && break || sleep 1
    done
else
    echo "running installer ($K3S_NODEGROUP/agent)"
    INSTALL_K3S_EXEC="agent"
    export INSTALL_K3S_EXEC
    "$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"
    echo "copying kube config from s3"
    for i in {1..120}; do
        echo -n "."
        aws s3 cp s3://"$PREFIX"-"$SUFFIX"/data/k3s/config /etc/rancher/k3s/k3s.yaml && echo "" && break || sleep 1
    done
    chmod 600 /etc/rancher/k3s/k3s.yaml

    echo "labeling node"
    /usr/local/bin/k3s kubectl --server "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml \
        label --overwrite node "$(hostname -f)" \
        node-role.kubernetes.io/agent=true
    /usr/local/bin/k3s kubectl --server "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml \
        label --overwrite node "$(hostname -f)" \
        nodegroup="$K3S_NODEGROUP"
fi
