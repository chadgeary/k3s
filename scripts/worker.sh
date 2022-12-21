#!/bin/bash

echo "running installer ($K3S_NODEGROUP/agent)"
INSTALL_K3S_EXEC="agent --kubelet-arg=provider-id=aws:///$AZ/$INSTANCE_ID --resolv-conf=/etc/rancher/k3s/resolv.conf"
export INSTALL_K3S_EXEC
"$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"
echo "copying kube config from s3"
for i in {1..120}; do
    echo -n "."
    aws --region "$REGION" s3 cp s3://"$PREFIX"-"$SUFFIX"-private/data/k3s/config /etc/rancher/k3s/k3s.yaml && echo "" && break || sleep 1
done
chmod 600 /etc/rancher/k3s/k3s.yaml

echo "labeling node"

/usr/local/bin/k3s kubectl --server "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml \
    label --overwrite=true node "$(hostname -f)" \
    kubernetes.io/arch="$ARCH" \
    kubernetes.io/cluster="$PREFIX"-"$SUFFIX" \
    kubernetes.io/node-group="$K3S_NODEGROUP" \
    node.kubernetes.io/instance-type="$INSTANCE_TYPE" \
    topology.kubernetes.io/region="$REGION" \
    topology.kubernetes.io/zone="$AZ"

# oidc (irsa)
echo "generating registries script and systemd service+timer"
tee /usr/local/bin/registries << EOM
#!/bin/bash

echo "getting ecr password"
ECR_PASSWORD=\$(aws --region "$REGION" ecr get-login-password)

echo "rendering /etc/rancher/k3s/registries.yaml"
tee /etc/rancher/k3s/registries.yaml << EOT > /dev/null
mirrors:
  "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com":
    endpoint:
      - "https://$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
  "$AWS_ADDON_URI":
    endpoint:
      - "https://$AWS_ADDON_URI"
configs:
  "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com":
    auth:
      username: AWS
      password: \$ECR_PASSWORD
  "$AWS_ADDON_URI":
    auth:
      username: AWS
      password: \$ECR_PASSWORD
EOT

echo "reloading k3s"
systemctl restart k3s-agent

EOM
chmod 700 /usr/local/bin/registries

tee /etc/systemd/system/k3s-registries.service << EOM
[Unit]
Description=Generates registries files from k3s api server and publishes to s3 every 11h
After=network.target
[Service]
ExecStart=/usr/local/bin/registries
Type=simple
Restart=no
[Install]
WantedBy=multi-user.target
EOM

tee /etc/systemd/system/k3s-registries.timer << EOM
[Unit]
Description=Generates registries files from k3s api server and publishes to s3 every 11h
[Timer]
OnUnitActiveSec=11h
Unit=k3s-registries.service
[Install]
WantedBy=multi-user.target
EOM

echo "activating registries script and systemd service+timer"
systemctl daemon-reload
systemctl enable k3s-registries.service k3s-registries.timer
systemctl start k3s-registries.service k3s-registries.timer