#!/bin/bash

# # aws-vpc-cni
# tee "$CHARTS_PATH"/aws-vpc-cni.yaml <<EOM
# cri:
#   hostPath:
#     path: /var/run/k3s/containerd/containerd.sock

# clusterName: $PREFIX-$SUFFIX
# backendSecurityGroup: $SECGROUP
# region: $REGION
# vpcId: $VPC

# enableShield: false
# enableWaf: false
# enableWafv2: false

# env:
#   ANNOTATE_POD_IP: true
#   ENABLE_POD_ENI: true
#   AWS_DEFAULT_REGION: $REGION
#   AWS_STS_REGIONAL_ENDPOINTS: "regional"
#   AWS_ROLE_ARN: arn:aws:iam::$ACCOUNT:role/$PREFIX-$SUFFIX-aws-vpc-cni
#   AWS_WEB_IDENTITY_TOKEN_FILE: "/var/run/secrets/serviceaccount/token"
#   CLUSTER_NAME: $PREFIX-$SUFFIX

# extraVolumeMounts:
#   - mountPath: /var/run/secrets/serviceaccount/
#     name: serviceaccount
# extraVolumes:
#   - name: serviceaccount
#     projected:
#       sources:
#         - serviceAccountToken:
#             path: token
#             expirationSeconds: 43200
#             audience: $PREFIX-$SUFFIX

# serviceAccount:
#   create: "true"
#   name: "aws-vpc-cni"

# image:
#   region: $REGION

# init:
#   image:
#     region: $REGION

# tolerations:
#   - operator: "Exists"

# EOM

# helm --kube-apiserver "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml upgrade --install \
#     --namespace kube-system aws-vpc-cni -f "$CHARTS_PATH"/aws-vpc-cni.yaml \
#     "$CHARTS_PATH"/aws-vpc-cni.tgz

# # awslbcontroller
# tee "$CHARTS_PATH"/awslbcontroller.yaml <<EOM
# clusterName: $PREFIX-$SUFFIX
# backendSecurityGroup: $SECGROUP
# region: $REGION
# vpcId: $VPC

# enableShield: false
# enableWaf: false
# enableWafv2: false

# env:
#   ANNOTATE_POD_IP: "false"
#   AWS_DEFAULT_REGION: $REGION
#   AWS_STS_REGIONAL_ENDPOINTS: "regional"
#   AWS_ROLE_ARN: arn:aws:iam::$ACCOUNT:role/$PREFIX-$SUFFIX-awslbcontroller
#   AWS_WEB_IDENTITY_TOKEN_FILE: "/var/run/secrets/serviceaccount/token"
#   CLUSTER_NAME: $PREFIX-$SUFFIX

# extraVolumeMounts:
#   - mountPath: /var/run/secrets/serviceaccount/
#     name: serviceaccount
# extraVolumes:
#   - name: serviceaccount
#     projected:
#       sources:
#         - serviceAccountToken:
#             path: token
#             expirationSeconds: 43200
#             audience: $PREFIX-$SUFFIX

# serviceAccount:
#   create: "true"
#   name: "awslbcontroller"

# image:
#   repository: $AWS_ADDON_URI/amazon/aws-load-balancer-controller

# replicaCount: 1
# tolerations:
#   - operator: "Exists"

# EOM

# install(s)
# helm --kube-apiserver "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml upgrade --install \
#     --namespace kube-system aws-load-balancer-controller -f "$CHARTS_PATH"/awslbcontroller.yaml \
#     "$CHARTS_PATH"/awslbcontroller.tgz

# # aws-cloud-controller-manager
# tee "$CHARTS_PATH"/aws-cloud-controller-manager.yaml <<EOM
# nodeSelector:
#   node-role.kubernetes.io/control-plane: "true"

# namespace: "kube-system"
# serviceAccountName: "aws-cloud-controller-manager"

# args:
#   - --allocate-node-cidrs=true
#   - --cloud-provider=aws
#   - --cluster-name=$PREFIX-$SUFFIX
#   - --cluster-cidr=10.42.0.0/16
#   - --use-service-account-credentials=true
#   - --v=2
# env:
#   - name: ANNOTATE_POD_IP
#     value: "false"
#   - name: AWS_DEFAULT_REGION
#     value: $REGION
#   - name: AWS_STS_REGIONAL_ENDPOINTS
#     value: "regional"
#   - name: AWS_ROLE_ARN
#     value: arn:aws:iam::$ACCOUNT:role/$PREFIX-$SUFFIX-aws-cloud-controller-manager
#   - name: AWS_WEB_IDENTITY_TOKEN_FILE
#     value: "/var/run/secrets/aws/serviceaccount/token"
#   - name: CLUSTER_NAME
#     value: $PREFIX-$SUFFIX

# extraVolumeMounts:
#   - mountPath: "/var/run/secrets/aws/serviceaccount/"
#     name: aws-token
# extraVolumes:
#   - name: aws-token
#     projected:
#       sources:
#         - serviceAccountToken:
#             path: token
#             expirationSeconds: 43200
#             audience: $PREFIX-$SUFFIX

# serviceAccount:
#   create: "true"
#   name: "aws-cloud-controller-manager"

# clusterRoleRules:
# - apiGroups:
#   - ""
#   resources:
#   - events
#   verbs:
#   - create
#   - patch
#   - update
# - apiGroups:
#   - ""
#   resources:
#   - nodes
#   verbs:
#   - '*'
# - apiGroups:
#   - ""
#   resources:
#   - nodes/status
#   verbs:
#   - patch
# - apiGroups:
#   - ""
#   resources:
#   - services
#   verbs:
#   - list
#   - patch
#   - update
#   - watch
# - apiGroups:
#   - ""
#   resources:
#   - services/status
#   verbs:
#   - list
#   - patch
#   - update
#   - watch
# - apiGroups:
#   - ""
#   resources:
#   - serviceaccounts
#   verbs:
#   - create
#   - get
#   - list
#   - patch
#   - update
#   - watch
# - apiGroups:
#   - ""
#   resources:
#   - persistentvolumes
#   verbs:
#   - get
#   - list
#   - update
#   - watch
# - apiGroups:
#   - ""
#   resources:
#   - endpoints
#   verbs:
#   - create
#   - get
#   - list
#   - watch
#   - update
# - apiGroups:
#   - coordination.k8s.io
#   resources:
#   - leases
#   verbs:
#   - create
#   - get
#   - list
#   - watch
#   - update
# - apiGroups:
#   - ""
#   resources:
#   - serviceaccounts/token
#   verbs:
#   - create

# image:
#   repository: $ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$PREFIX-$SUFFIX-codebuild/$ARCH/registry.k8s.io/provider-aws/cloud-controller-manager
#   tag: v1.25.1

# EOM

# helm --kube-apiserver "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml upgrade --install \
#     --namespace kube-system aws-cloud-controller-manager -f "$CHARTS_PATH"/aws-cloud-controller-manager.yaml \
#     "$CHARTS_PATH"/aws-cloud-controller-manager.tgz
