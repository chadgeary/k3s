#!/bin/bash

echo "INFO: labeling node"

until /usr/local/bin/k3s kubectl --server "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml \
    label --overwrite=true node "$(hostname -f)" \
    kubernetes.io/arch="$ARCH" \
    kubernetes.io/cluster="$PREFIX"-"$SUFFIX" \
    kubernetes.io/node-group="$K3S_NODEGROUP" \
    node.kubernetes.io/ami-type="$AMI_TYPE" \
    node.kubernetes.io/instance-type="$INSTANCE_TYPE" \
    topology.kubernetes.io/region="$REGION" \
    topology.kubernetes.io/zone="$AWS_AZ"
do
    echo "INFO: unable to label, retrying"
    sleep 3
    resolvectl flush-caches
done
