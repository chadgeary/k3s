#!/bin/bash

# various vars - the curl to 169.254.169.254 are AWS instance-specific API facts
HOOKRESULT='CONTINUE'
AWS_METADATA_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')
SLEEP_SECONDS=90

# drain
echo "INFO: draining"
/usr/local/bin/k3s kubectl --server "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml \
    drain "$(hostname -f)" \
    --grace-period=$SLEEP_SECONDS \
    --ignore-daemonsets \
    --force

sleep $SLEEP_SECONDS

# k3s killall
echo "INFO: k3s-killall.sh"
/usr/local/bin/k3s-killall.sh

# delete node
echo "INFO: kubectl delete node"
/usr/local/bin/k3s kubectl --server "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml \
    delete node "$(hostname -f)"

# notify aws complete
echo "INFO: aws autoscaling complete-lifecycle-action"
aws autoscaling complete-lifecycle-action \
  --lifecycle-hook-name "$LIFECYCLEHOOKNAME" \
  --auto-scaling-group-name "$ASGNAME" \
  --lifecycle-action-result $HOOKRESULT \
  --instance-id "$INSTANCE_ID" \
  --region "$REGION"
