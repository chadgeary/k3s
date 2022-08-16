#!/bin/bash

# Get kubeconfig
echo "Polling for k3s.yaml via s3"
until aws --profile default --region us-east-1 \
  s3 cp \
  s3://k3s-i43rg/data/k3s/k3s.yaml \
  k3s-i43rg.kubeconfig.yaml
do
  sleep 1
  echo -n "."
done
echo ""

# Get an instance id
echo "Polling for a running instance to use as proxy"
until aws --profile default --region us-east-1 \
    ec2 describe-instances \
    --query 'Reservations[].Instances[] | [0].InstanceId' \
    --filters Name=tag:Cluster,Values=k3s-i43rg Name=instance-state-name,Values=running \
    --output text
do
  sleep 1
  echo -n "."
done
echo ""
SSM_INSTANCE=$(aws --profile default --region us-east-1 \
    ec2 describe-instances \
    --query 'Reservations[].Instances[] | [0].InstanceId' \
    --filters Name=tag:Cluster,Values=k3s-i43rg Name=instance-state-name,Values=running \
    --output text)

# Forward k3s kubeapi port (6443)
echo "Found $SSM_INSTANCE, attempting AWS-StartPortForwardingSession"
until aws --profile default --region us-east-1 \
  ssm start-session \
  --target $SSM_INSTANCE --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["6443"],"localPortNumber":["6443"]}' &
do
  sleep 1
  echo -n "."
done

echo "Connected, use --kubeconfig with kubectl and helm, e.g.:
kubectl get nodes --kubeconfig=k3s-i43rg.kubeconfig.yaml"
