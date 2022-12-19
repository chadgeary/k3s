#!/bin/bash

# various vars - the curl to 169.254.169.254 are AWS instance-specific API facts
HOOKRESULT='CONTINUE'
AWS_METADATA_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')

# drain
/usr/local/bin/k3s kubectl --server "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml \
    drain "$(hostname -f)" \
    --grace-period=90 \
    --ignore-daemonsets \
    --force

# k3s killall
/usr/local/bin/k3s-killall.sh

# notify aws complete
aws autoscaling complete-lifecycle-action \
  --lifecycle-hook-name $LIFECYCLEHOOKNAME \
  --auto-scaling-group-name $ASGNAME \
  --lifecycle-action-result $HOOKRESULT \
  --instance-id $INSTANCEID \
  --region $REGION
