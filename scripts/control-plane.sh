#!/bin/bash

set -x
echo "INFO: determining if first control-plane instance"
FIRST_INSTANCE_PARAMETER=$(/usr/local/bin/aws --region "$REGION" ssm get-parameter --with-decryption --name /"$PREFIX"-"$SUFFIX"/FIRST_INSTANCE_ID --query Parameter.Value --output text)
FIRST_INSTANCE_ID=$(/usr/local/bin/aws ec2 describe-instances --filters "Name=tag:Name,Values=control-plane.$PREFIX-$SUFFIX.internal" "Name=instance-state-name,Values=running" --query 'sort_by(Reservations[].Instances[], &LaunchTime)[0].[InstanceId]' --output text)
if [ "$FIRST_INSTANCE_PARAMETER" == "unset" ] && [ "$INSTANCE_ID" == "$FIRST_INSTANCE_ID" ]; then
    echo "INFO: SSM parameter is unset and matching FIRST_INSTANCE_ID, will cluster-init"
    unset K3S_URL
    /usr/local/bin/aws --region "$REGION" ssm put-parameter --name /"$PREFIX"-"$SUFFIX"/FIRST_INSTANCE_ID --value "$INSTANCE_ID" --overwrite
    CONTROLPLANE_INIT_ARG="--cluster-init"
    export CONTROLPLANE_INIT_ARG
else
    echo "INFO: SSM parameter is set or not matching FIRST_INSTANCE_ID, skipping cluster-init"
    CONTROLPLANE_INIT_ARG="--server $K3S_URL"
    export CONTROLPLANE_INIT_ARG
fi

echo "INFO: installing k3s"
INSTALL_K3S_EXEC="server $CONTROLPLANE_INIT_ARG --resolv-conf=/etc/rancher/k3s/resolv.conf --kubelet-arg=provider-id=aws:///$AWS_AZ/$INSTANCE_ID --kube-apiserver-arg=api-audiences=$PREFIX-$SUFFIX --kube-apiserver-arg=service-account-issuer=https://s3.$REGION.amazonaws.com/$PREFIX-$SUFFIX-public/oidc --kube-apiserver-arg=service-account-jwks-uri=https://s3.$REGION.amazonaws.com/$PREFIX-$SUFFIX-public/oidc/openid/v1/jwks --flannel-backend=none --cluster-cidr=$POD_CIDR --service-cidr=$SVC_CIDR --cluster-dns=$KUBEDNS_IP --disable-network-policy --disable=traefik --disable=servicelb --disable-cloud-controller --node-label=node.kubernetes.io/instance-type=$INSTANCE_TYPE --node-taint=node-role.kubernetes.io/control-plane:NoSchedule --node-taint=node.cilium.io/agent-not-ready:NoSchedule --tls-san=control-plane.$PREFIX-$SUFFIX.internal --node-ip $INSTANCE_IP --advertise-address $INSTANCE_IP"
export INSTALL_K3S_EXEC
"$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"

echo "INFO: copying /etc/rancher/k3s/k3s.yaml to s3://"$PREFIX"-"$SUFFIX"-private/data/k3s/config"
for i in {1..120}; do
    echo -n "."
    /usr/local/bin/aws --region "$REGION" s3 cp /etc/rancher/k3s/k3s.yaml s3://"$PREFIX"-"$SUFFIX"-private/data/k3s/config && echo "" && break || sleep 1
done

# labels
bash label.sh

# oidc
bash oidc.sh

# ecr
bash ecr.sh

# charts
bash charts.sh
