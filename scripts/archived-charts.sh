#!/bin/bash

# aws-ebs-csi-driver
tee "$CHARTS_PATH"/aws-ebs-csi-driver.yaml >/dev/null <<EOM

image:
  repository: $ECR_URI_PREFIX-ecr/ebs-csi-driver/aws-ebs-csi-driver

sidecars:
  provisioner:
    image:
      repository: $ECR_URI_PREFIX-codebuild/k8s.gcr.io/sig-storage/csi-provisioner
      tag: "v3.1.0"
  attacher:
    image:
      repository: $ECR_URI_PREFIX-codebuild/k8s.gcr.io/sig-storage/csi-attacher
      tag: "v3.4.0"
  snapshotter:
    image:
      repository: $ECR_URI_PREFIX-codebuild/k8s.gcr.io/sig-storage/csi-snapshotter
      tag: "v6.0.1"
  livenessProbe:
    image:
      repository: $ECR_URI_PREFIX-codebuild/k8s.gcr.io/sig-storage/livenessprobe
      tag: "v2.6.0"
  resizer:
    image:
      repository: $ECR_URI_PREFIX-codebuild/k8s.gcr.io/sig-storage/csi-resizer
      tag: "v1.4.0"
  nodeDriverRegistrar:
    image:
      repository: $ECR_URI_PREFIX-codebuild/k8s.gcr.io/sig-storage/csi-node-driver-registrar
      tag: "v2.5.1"

controller:
  env:
  - name: AWS_DEFAULT_REGION
    value: "$REGION"
  - name: AWS_REGION
    value: "$REGION"
  - name: AWS_ROLE_ARN
    value: "arn:aws:iam::$ACCOUNT:role/$PREFIX-$SUFFIX-aws-ebs-csi-driver"
  - name: AWS_WEB_IDENTITY_TOKEN_FILE
    value: "/var/run/secrets/kubernetes.io/serviceaccount/token"
  - name: AWS_STS_REGIONAL_ENDPOINTS
    value: regional

  nodeSelector:
    node-role.kubernetes.io/control-plane: "true"
  region: $REGION
  replicaCount: 1
  tolerations:
  - effect: NoSchedule
    operator: Exists

  volumes:
  - name: serviceaccount
    projected:
      sources:
      - serviceAccountToken:
          path: token
          expirationSeconds: 43200
          audience: $PREFIX-$SUFFIX
  volumeMounts:
  - mountPath: "/var/run/secrets/kubernetes.io/serviceaccount/"
    name: serviceaccount

node:
  env:
  - name: AWS_DEFAULT_REGION
    value: "$REGION"
  - name: AWS_REGION
    value: "$REGION"
  tolerations:
  - effect: NoSchedule
    operator: Exists

storageClasses:
- name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
  mountOptions:
  - tls
  parameters:
    encrypted: "true"
    kmsKeyId: "$EBS_KMS_ARN"
  reclaimPolicy: Delete
  volumeBindingMode: WaitForFirstConsumer
EOM

helm --kube-apiserver https://localhost:6443 --kubeconfig /etc/rancher/k3s/k3s.yaml upgrade --install \
    --namespace kube-system aws-ebs-csi-driver -f "$CHARTS_PATH"/aws-ebs-csi-driver.yaml \
    "$CHARTS_PATH"/aws-ebs-csi-driver.tgz