#!/bin/bash

echo "running installer (control-plane)"
INSTALL_K3S_EXEC="server --resolv-conf=/etc/rancher/k3s/resolv.conf --kubelet-arg=provider-id=aws:///$AZ/$INSTANCE_ID --kube-apiserver-arg=api-audiences=$PREFIX-$SUFFIX --kube-apiserver-arg=service-account-issuer=https://s3.$REGION.amazonaws.com/$PREFIX-$SUFFIX-public/oidc --kube-apiserver-arg=service-account-jwks-uri=https://s3.$REGION.amazonaws.com/$PREFIX-$SUFFIX-public/oidc/openid/v1/jwks --flannel-backend=none --cluster-cidr=$POD_CIDR --service-cidr=$SVC_CIDR --cluster-dns=$KUBEDNS_IP --disable-network-policy --disable=traefik --disable=servicelb --disable-cloud-controller --node-label=node.kubernetes.io/instance-type=$INSTANCE_TYPE --node-taint=node-role.kubernetes.io/control-plane:NoSchedule --node-taint=node.cilium.io/agent-not-ready:NoSchedule --tls-san=control-plane.$PREFIX-$SUFFIX.internal"
export INSTALL_K3S_EXEC
"$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"

echo "labeling node"

# labels
until /usr/local/bin/k3s kubectl --server https://localhost:6443 --kubeconfig /etc/rancher/k3s/k3s.yaml \
    label --overwrite=true node "$(hostname -f)" \
    kubernetes.io/arch="$ARCH" \
    kubernetes.io/cluster="$PREFIX"-"$SUFFIX" \
    kubernetes.io/node-group="$K3S_NODEGROUP" \
    node.kubernetes.io/instance-type="$INSTANCE_TYPE" \
    topology.kubernetes.io/region="$REGION" \
    topology.kubernetes.io/zone="$AZ"
do
    echo "unable to label, retrying"
    sleep 10
done

echo "copying kube config to s3 (private)"
for i in {1..120}; do
    echo -n "."
    /usr/local/bin/aws --region "$REGION" s3 cp /etc/rancher/k3s/k3s.yaml s3://"$PREFIX"-"$SUFFIX"-private/data/k3s/config && echo "" && break || sleep 1
done

# helm
if [ -f "$K3S_BIN_PATH/$HELM_BIN_FILE" ]; then
    echo "helm exists, skipping"
else
    /usr/local/bin/aws --region "$REGION" s3 cp s3://"$PREFIX"-"$SUFFIX"-private/data/downloads/k3s/"$HELM_BIN_FILE"-"$ARCH".tar.gz /opt/"$HELM_BIN_FILE"-"$ARCH".tar.gz
    if [ "$ARCH" == "arm64" ]; then
        tar -zx -f /opt/"$HELM_BIN_FILE"-"$ARCH".tar.gz --strip-components=1 --directory "$K3S_BIN_PATH" "linux-arm64/helm"
    else
        tar -zx -f /opt/"$HELM_BIN_FILE"-"$ARCH".tar.gz --strip-components=1 --directory "$K3S_BIN_PATH" "linux-amd64/helm"
    fi
    chmod +x "$K3S_BIN_PATH"/"$HELM_BIN_FILE"
fi

# charts
echo "Installing charts"
bash charts.sh

# oidc (irsa)
echo "generating oidc script and systemd service+timer"
tee /usr/local/bin/oidc << EOM
#!/bin/bash

echo "decoding x509"
awk -F': ' '/client-certificate-data/ {print \$2}' /etc/rancher/k3s/k3s.yaml | base64 -d > /etc/rancher/k3s/system.admin.pem && chmod 400 /etc/rancher/k3s/system.admin.pem
awk -F': ' '/client-key-data/ {print \$2}' /etc/rancher/k3s/k3s.yaml | base64 -d > /etc/rancher/k3s/system.admin.key && chmod 400 /etc/rancher/k3s/system.admin.key
awk -F': ' '/certificate-authority-data/ {print \$2}' /etc/rancher/k3s/k3s.yaml | base64 -d > /etc/rancher/k3s/system.ca.pem && chmod 400 /etc/rancher/k3s/system.ca.pem

echo "decoding thumbprint"
openssl x509 -in /etc/rancher/k3s/system.ca.pem -fingerprint -noout | awk -F'=' 'gsub(/:/,"",\$0) { print \$2 }' > /etc/rancher/k3s/system.ca.thumbprint && chmod 400 /etc/rancher/k3s/system.ca.thumbprint

echo "fetching oidc"
curl --cert /etc/rancher/k3s/system.admin.pem --key /etc/rancher/k3s/system.admin.key --cacert /etc/rancher/k3s/system.ca.pem https://localhost:6443/.well-known/openid-configuration > /etc/rancher/k3s/oidc
curl --cert /etc/rancher/k3s/system.admin.pem --key /etc/rancher/k3s/system.admin.key --cacert /etc/rancher/k3s/system.ca.pem https://localhost:6443/openid/v1/jwks > /etc/rancher/k3s/jwks

echo "posting oidc to s3 (private)"
/usr/local/bin/aws --region $REGION s3 cp /etc/rancher/k3s/system.ca.thumbprint s3://$PREFIX-$SUFFIX-private/oidc/thumbprint
/usr/local/bin/aws --region $REGION s3 cp /etc/rancher/k3s/oidc s3://$PREFIX-$SUFFIX-private/oidc/.well-known/openid-configuration
/usr/local/bin/aws --region $REGION s3 cp /etc/rancher/k3s/jwks s3://$PREFIX-$SUFFIX-private/oidc/openid/v1/jwks
EOM

chmod 700 /usr/local/bin/oidc

tee /etc/systemd/system/k3s-oidc.service << EOM
[Unit]
Description=Generates oidc files from k3s api server and publishes to s3 every 23h
After=network.target
[Service]
ExecStart=/usr/local/bin/oidc
Type=simple
Restart=no
[Install]
WantedBy=multi-user.target
EOM

tee /etc/systemd/system/k3s-oidc.timer << EOM
[Unit]
Description=Generates oidc files from k3s api server and publishes to s3 every 23h
[Timer]
OnUnitActiveSec=23h
Unit=k3s-oidc.service
[Install]
WantedBy=multi-user.target
EOM

echo "activating oidc script and systemd service+timer"
systemctl daemon-reload
systemctl enable k3s-oidc.service k3s-oidc.timer
systemctl start k3s-oidc.service k3s-oidc.timer

echo "generating registries script and systemd service+timer"
tee /usr/local/bin/registries << EOM
#!/bin/bash

echo "getting ecr password"
ECR_PASSWORD=\$(/usr/local/bin/aws --region "$REGION" ecr get-login-password)

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
systemctl restart k3s

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
