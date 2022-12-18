#!/bin/bash

# aws-cloud-controller-manager
tee "$CHARTS_PATH"/aws-cloud-controller-manager.yaml <<EOM

namespace: "kube-system"
args:
  - --v=2
  - --cloud-provider=aws
image:
    repository: $ECR_URI_PREFIX-codebuild/$ARCH/registry.k8s.io/provider-aws/cloud-controller-manager/provider-aws/cloud-controller-manager
    tag: v1.25.1
nameOverride: "aws-cloud-controller-manager"
nodeSelector:
  node-role.kubernetes.io/control-plane: ""

clusterRoleRules:
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - patch
  - update
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - '*'
- apiGroups:
  - ""
  resources:
  - nodes/status
  verbs:
  - patch
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - list
  - patch
  - update
  - watch
- apiGroups:
  - ""
  resources:
  - services/status
  verbs:
  - list
  - patch
  - update
  - watch
- apiGroups:
  - ""
  resources:
  - serviceaccounts
  verbs:
  - create
- apiGroups:
  - ""
  resources:
  - persistentvolumes
  verbs:
  - get
  - list
  - update
  - watch
- apiGroups:
  - ""
  resources:
  - endpoints
  verbs:
  - create
  - get
  - list
  - watch
  - update
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - create
  - get
  - list
  - watch
  - update
- apiGroups:
  - ""
  resources:
  - serviceaccounts/token
  verbs:
  - create

resources:
  requests:
    cpu: 200m

tolerations:
- key: node.cloudprovider.kubernetes.io/uninitialized
  value: "true"
  effect: NoSchedule
- key: node-role.kubernetes.io/master
  effect: NoSchedule
- key: node-role.kubernetes.io/control-plane
  effect: NoSchedule

dnsPolicy: Default
clusterRoleName : system:cloud-controller-manager
roleBindingName: cloud-controller-manager:apiserver-authentication-reader
serviceAccountName: cloud-controller-manager
roleName: extension-apiserver-authentication-reader

EOM

helm --kube-apiserver "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml upgrade --install \
    --namespace kube-system aws-cloud-controller-manager -f "$CHARTS_PATH"/aws-cloud-controller-manager.yaml \
    "$CHARTS_PATH"/aws-cloud-controller-manager.tgz

# calico
tee "$CHARTS_PATH"/calico.yaml <<EOM
tigeraOperator:
  image: tigera/operator
  registry: $ECR_URI_PREFIX-quay
calicoctl:
  image: $ECR_URI_PREFIX-quay/calico/ctl
installation:
  kubernetesProvider: EKS
  cni:
    type: Calico
  calicoNetwork:
    bgp: Disabled
    ipPools:
    - blockSize: 24
      cidr: $POD_CIDR
      encapsulation: VXLANCrossSubnet
  containerIPForwarding: "Enabled"
  controlPlaneReplicas: 1
  registry: $ECR_URI_PREFIX-quay

EOM

helm --kube-apiserver "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml upgrade --install \
    --namespace kube-system calico -f "$CHARTS_PATH"/calico.yaml \
    "$CHARTS_PATH"/calico.tgz

# lb controller
tee "$CHARTS_PATH"/aws-lb-controller.yaml <<EOM

image:
  repository: $AWS_ADDON_URI/amazon/aws-load-balancer-controller
  tag: v2.4.5
region: "$REGION"
clusterName: $PREFIX-$SUFFIX
cluster:
  dnsDomain: $PREFIX-$SUFFIX.internal
env:
  AWS_DEFAULT_REGION: "$REGION"
  AWS_ROLE_ARN: "arn:aws:iam::$ACCOUNT:role/$PREFIX-$SUFFIX-aws-lb-controller"
  AWS_WEB_IDENTITY_TOKEN_FILE: "/var/run/secrets/kubernetes.io/serviceaccount/token"
  AWS_STS_REGIONAL_ENDPOINTS: regional
replicaCount: 1
tolerations:
- key: node-role.kubernetes.io/master
  effect: NoSchedule
- key: node-role.kubernetes.io/control-plane
  effect: NoSchedule
vpcId: $VPC

EOM

helm --kube-apiserver "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml upgrade --install \
    --namespace kube-system aws-lb-controller -f "$CHARTS_PATH"/aws-lb-controller.yaml \
    "$CHARTS_PATH"/aws-lb-controller.tgz

# external-dns
tee "$CHARTS_PATH"/external-dns.yaml <<EOM

image:
  registry: $ECR_URI_PREFIX-codebuild/$ARCH
  repository: ghcr.io/zcube/bitnami-compat/external-dns
  tag: 0
aws:
  region: "$REGION"
tolerations:
- key: node-role.kubernetes.io/master
  effect: NoSchedule
- key: node-role.kubernetes.io/control-plane
  effect: NoSchedule
extraEnvVars:
- name: AWS_DEFAULT_REGION
  value: "$REGION"
- name: AWS_ROLE_ARN
  value: "arn:aws:iam::$ACCOUNT:role/$PREFIX-$SUFFIX-external-dns"
- name: AWS_WEB_IDENTITY_TOKEN_FILE
  value: "/var/run/secrets/kubernetes.io/serviceaccount/token"
- name: AWS_STS_REGIONAL_ENDPOINTS
  value: regional

EOM

if [ $NAT_GATEWAYS == "true" ]; then
  helm --kube-apiserver "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml upgrade --install \
      --namespace kube-system external-dns -f "$CHARTS_PATH"/external-dns.yaml \
      "$CHARTS_PATH"/external-dns.tgz
else
  echo "INFO: Skipping external-dns, NAT_GATEWAYS = $NAT_GATEWAYS"
fi
