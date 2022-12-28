#!/bin/bash
set -x
echo "determining if first control-plane instance"
FIRST_INSTANCE_PARAMETER=$(/usr/local/bin/aws --region "$REGION" ssm get-parameter --with-decryption --name /"$PREFIX"-"$SUFFIX"/FIRST_INSTANCE_ID --query Parameter.Value --output text)
FIRST_INSTANCE_ID=$(/usr/local/bin/aws ec2 describe-instances --filters "Name=tag:Name,Values=control-plane.$PREFIX-$SUFFIX.internal" --query 'sort_by(Reservations[].Instances[], &LaunchTime)[0].[InstanceId]' --output text)
if [ $FIRST_INSTANCE_PARAMETER == "unset" ] || [ $INSTANCE_ID == $FIRST_INSTANCE_ID ]; then
    unset K3S_URL
    /usr/local/bin/aws --region "$REGION" ssm put-parameter --name /"$PREFIX"-"$SUFFIX"/FIRST_INSTANCE_ID --value $INSTANCE_ID --overwrite
    CONTROLPLANE_INIT_ARG="--cluster-init"
    export $CONTROLPLANE_INIT_ARG
else
    CONTROLPLANE_INIT_ARG="--server $K3S_URL"
    export $CONTROLPLANE_INIT_ARG
fi

echo "running installer (control-plane)"
INSTALL_K3S_EXEC="server $CONTROLPLANE_INIT_ARG --resolv-conf=/etc/rancher/k3s/resolv.conf --kubelet-arg=provider-id=aws:///$AZ/$INSTANCE_ID --kube-apiserver-arg=api-audiences=$PREFIX-$SUFFIX --kube-apiserver-arg=service-account-issuer=https://s3.$REGION.amazonaws.com/$PREFIX-$SUFFIX-public/oidc --kube-apiserver-arg=service-account-jwks-uri=https://s3.$REGION.amazonaws.com/$PREFIX-$SUFFIX-public/oidc/openid/v1/jwks --flannel-backend=none --cluster-cidr=$POD_CIDR --service-cidr=$SVC_CIDR --cluster-dns=$KUBEDNS_IP --disable-network-policy --disable=traefik --disable=servicelb --disable-cloud-controller --node-label=node.kubernetes.io/instance-type=$INSTANCE_TYPE --node-taint=node-role.kubernetes.io/control-plane:NoSchedule --node-taint=node.cilium.io/agent-not-ready:NoSchedule --tls-san=control-plane.$PREFIX-$SUFFIX.internal --node-ip $INSTANCE_IP --advertise-address $INSTANCE_IP"
export INSTALL_K3S_EXEC
"$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"

echo "labeling node"

# labels
until /usr/local/bin/k3s kubectl --server https://localhost:6443 --kubeconfig /etc/rancher/k3s/k3s.yaml \
    label --overwrite=true node "$(hostname -f)" \
    kubernetes.io/arch="$ARCH" \
    kubernetes.io/cluster="$PREFIX"-"$SUFFIX" \
    kubernetes.io/node-group="$K3S_NODEGROUP" \
    node.kubernetes.io/instance-type="$INSTANCE_TYPE" \
    topology.kubernetes.io/region="$REGION" \
    topology.kubernetes.io/zone="$AZ"
do
    echo "unable to label, retrying"
    sleep 5
    resolvectl flush-caches
done

echo "copying kube config to s3 (private)"
for i in {1..120}; do
    echo -n "."
    /usr/local/bin/aws --region "$REGION" s3 cp /etc/rancher/k3s/k3s.yaml s3://"$PREFIX"-"$SUFFIX"-private/data/k3s/config && echo "" && break || sleep 1
done

# helm
if [ -f "$K3S_BIN_PATH/$HELM_BIN_FILE" ]; then
    echo "helm exists, skipping"
else
    /usr/local/bin/aws --region "$REGION" s3 cp s3://"$PREFIX"-"$SUFFIX"-private/data/downloads/k3s/"$HELM_BIN_FILE"-"$ARCH".tar.gz /opt/"$HELM_BIN_FILE"-"$ARCH".tar.gz
    if [ "$ARCH" == "arm64" ]; then
        tar -zx -f /opt/"$HELM_BIN_FILE"-"$ARCH".tar.gz --strip-components=1 --directory "$K3S_BIN_PATH" "linux-arm64/helm"
    else
        tar -zx -f /opt/"$HELM_BIN_FILE"-"$ARCH".tar.gz --strip-components=1 --directory "$K3S_BIN_PATH" "linux-amd64/helm"
    fi
    chmod +x "$K3S_BIN_PATH"/"$HELM_BIN_FILE"
fi

# ecr
echo "Installing ecr auth script"
bash ecr.sh

# charts
echo "Installing charts"
bash charts.sh

# oidc
echo "Installing oidc script"
bash oidc.sh
