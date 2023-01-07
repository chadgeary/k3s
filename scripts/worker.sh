#!/bin/bash

echo "INFO: running installer ($K3S_NODEGROUP/agent)"
INSTALL_K3S_EXEC="agent --server $K3S_URL --kubelet-arg=provider-id=aws:///$AWS_AZ/$INSTANCE_ID --resolv-conf=/etc/rancher/k3s/resolv.conf --node-label=node.kubernetes.io/instance-type=$INSTANCE_TYPE --node-taint=node.cilium.io/agent-not-ready:NoSchedule --node-ip $INSTANCE_IP"
export INSTALL_K3S_EXEC
"$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"
echo "INFO: copying kube config from s3"
for i in {1..120}; do
    echo -n "."
    /usr/local/bin/aws --region "$REGION" s3 cp s3://"$PREFIX"-"$SUFFIX"-private/data/k3s/config /etc/rancher/k3s/k3s.yaml && echo "" && break || sleep 1
done
chmod 600 /etc/rancher/k3s/k3s.yaml

# labels
bash label.sh

# ecr
bash ecr.sh
