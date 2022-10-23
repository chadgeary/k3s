#!/bin/bash

ARCH=$(uname -m)
DB_PASS=$(aws --region "$AWS_REGION" ssm get-parameter --with-decryption --name /"$PREFIX"-"$SUFFIX"/DB_PASS --query Parameter.Value --output text)
K3S_TOKEN=$(aws --region "$AWS_REGION" ssm get-parameter --with-decryption --name /"$PREFIX"-"$SUFFIX"/K3S_TOKEN --query Parameter.Value --output text)
K3S_BIN_PATH="/usr/local/bin"
K3S_BIN_FILE="k3s"
K3S_TAR_PATH="/var/lib/rancher/k3s/agent/images"
K3S_TAR_FILE="k3s-airgap-images"
K3S_INSTALL_PATH="/usr/local/bin"
K3S_INSTALL_FILE="install.sh"
K3S_DATASTORE_ENDPOINT="postgres://$PREFIX$SUFFIX:$DB_PASS@$DB_ENDPOINT/$PREFIX$SUFFIX"
INSTALL_K3S_SKIP_DOWNLOAD="true"
export ARCH DB_PASS K3S_TOKEN K3S_BIN_PATH K3S_BIN_FILE K3S_TAR_PATH K3S_TAR_FILE K3S_INSTALL_PATH K3S_INSTALL_FILE K3S_DATASTORE_ENDPOINT INSTALL_K3S_SKIP_DOWNLOAD

# k3s binary
if [ -f "$K3S_BIN_PATH/$K3S_BIN_FILE" ]; then
    echo "bin exists, skipping"
else
    aws --region "$AWS_REGION" s3 cp s3://"$PREFIX"-"$SUFFIX"-private/data/downloads/k3s/"$K3S_BIN_FILE"-"$ARCH" "$K3S_BIN_PATH"/"$K3S_BIN_FILE"
    chmod +x "$K3S_BIN_PATH"/"$K3S_BIN_FILE"
fi

# k3s directories
mkdir -p /etc/rancher/k3s /var/lib/rancher/k3s/agent/images
chmod 750 /etc/rancher/k3s /var/lib/rancher/k3s/agent/images

# k3s tar
if [ -f "$K3S_TAR_PATH/$K3S_TAR_FILE".tar ]; then
    echo "tar exists, skipping"
else
    aws --region "$AWS_REGION" s3 cp s3://"$PREFIX"-"$SUFFIX"-private/data/downloads/k3s/"$K3S_TAR_FILE"-"$ARCH".tar "$K3S_TAR_PATH"/"$K3S_TAR_FILE".tar
fi

# k3s install
if [ -f "$K3S_INSTALL_PATH/$K3S_INSTALL_FILE" ]; then
    echo "bin exists, skipping"
else
    aws --region "$AWS_REGION" s3 cp s3://"$PREFIX"-"$SUFFIX"-private/scripts/"$K3S_INSTALL_FILE" "$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"
    chmod +x "$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"
fi

# k3s dns
grep nameserver /etc/resolv.conf > /etc/rancher/k3s/resolv.conf

# k3s install exec
if [ "$K3S_NODEGROUP" == "master" ]; then
    echo "running installer (master/server)"
    INSTALL_K3S_EXEC="server --resolv-conf=/etc/rancher/k3s/resolv.conf --kube-apiserver-arg=api-audiences=$PREFIX-$SUFFIX --kube-apiserver-arg=service-account-issuer=https://s3.$AWS_REGION.amazonaws.com/$PREFIX-$SUFFIX-public/oidc --kube-apiserver-arg=service-account-jwks-uri=https://s3.$AWS_REGION.amazonaws.com/$PREFIX-$SUFFIX-public/oidc/openid/v1/jwks"
    export INSTALL_K3S_EXEC
    "$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"

    echo "labeling node"
    /usr/local/bin/k3s kubectl --server "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml \
        label --overwrite=true node "$(hostname -f)" \
        nodegroup="$K3S_NODEGROUP"

    echo "tainting node (node-role.kubernetes.io/control-plane:NoSchedule)"
    /usr/local/bin/k3s kubectl --server "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml \
        taint --overwrite=true node "$(hostname -f)" \
        node-role.kubernetes.io/control-plane:NoSchedule

    if [ "$ARCH" == "aarch64" ]; then
        echo "tainting node (arm64:NoSchedule)"
        /usr/local/bin/k3s kubectl --server "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml \
        taint --overwrite=true node "$(hostname -f)" \
        kubernetes.io/arch=arm64:NoSchedule
    fi

    echo "copying kube config to s3 (private)"
    for i in {1..120}; do
        echo -n "."
        aws --region "$AWS_REGION" s3 cp /etc/rancher/k3s/k3s.yaml s3://"$PREFIX"-"$SUFFIX"-private/data/k3s/config && echo "" && break || sleep 1
    done

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
aws --region $AWS_REGION s3 cp /etc/rancher/k3s/system.ca.thumbprint s3://$PREFIX-$SUFFIX-private/oidc/thumbprint
aws --region $AWS_REGION s3 cp /etc/rancher/k3s/oidc s3://$PREFIX-$SUFFIX-private/oidc/.well-known/openid-configuration
aws --region $AWS_REGION s3 cp /etc/rancher/k3s/jwks s3://$PREFIX-$SUFFIX-private/oidc/openid/v1/jwks
EOM
    chmod 700 /usr/local/bin/oidc

    tee /etc/systemd/system/k3s-oidc.service << EOM
[Unit]
Description=Generates oidc files from k3s api server and publishes to s3 every 24h
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
Description=Generates oidc files from k3s api server and publishes to s3 every 24h
[Timer]
OnUnitActiveSec=24h
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
ECR_PASSWORD=\$(aws --region "$AWS_REGION" ecr get-login-password)

echo "rendering /etc/rancher/k3s/registries.yaml"
tee /etc/rancher/k3s/registries.yaml << EOT > /dev/null
mirrors:
  "$ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com":
    endpoint:
      - "https://$ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com"
configs:
  "$ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com":
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
Description=Generates registries files from k3s api server and publishes to s3 every 6h
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
Description=Generates registries files from k3s api server and publishes to s3 every 6h
[Timer]
OnUnitActiveSec=6h
Unit=k3s-registries.service
[Install]
WantedBy=multi-user.target
EOM

    echo "activating registries script and systemd service+timer"
    systemctl daemon-reload
    systemctl enable k3s-registries.service k3s-registries.timer
    systemctl start k3s-registries.service k3s-registries.timer

else
    echo "running installer ($K3S_NODEGROUP/agent)"
    INSTALL_K3S_EXEC="agent --resolv-conf=/etc/rancher/k3s/resolv.conf"
    export INSTALL_K3S_EXEC
    "$K3S_INSTALL_PATH"/"$K3S_INSTALL_FILE"
    echo "copying kube config from s3"
    for i in {1..120}; do
        echo -n "."
        aws --region "$AWS_REGION" s3 cp s3://"$PREFIX"-"$SUFFIX"-private/data/k3s/config /etc/rancher/k3s/k3s.yaml && echo "" && break || sleep 1
    done
    chmod 600 /etc/rancher/k3s/k3s.yaml

    echo "labeling node"
    /usr/local/bin/k3s kubectl --server "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml \
        label --overwrite=true node "$(hostname -f)" \
        node-role.kubernetes.io/agent=true
    /usr/local/bin/k3s kubectl --server "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml \
        label --overwrite=true node "$(hostname -f)" \
        nodegroup="$K3S_NODEGROUP"

    if [ "$ARCH" == "aarch64" ]; then
        echo "tainting node (arm64:NoSchedule)"
        /usr/local/bin/k3s kubectl --server "$K3S_URL" --kubeconfig /etc/rancher/k3s/k3s.yaml \
        taint --overwrite=true node "$(hostname -f)" \
        kubernetes.io/arch=arm64:NoSchedule
    fi

    echo "generating registries script and systemd service+timer"
    tee /usr/local/bin/registries << EOM
#!/bin/bash

echo "getting ecr password"
ECR_PASSWORD=\$(aws --region "$AWS_REGION" ecr get-login-password)

echo "rendering /etc/rancher/k3s/registries.yaml"
tee /etc/rancher/k3s/registries.yaml << EOT > /dev/null
mirrors:
  "$ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com":
    endpoint:
      - "https://$ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com"
configs:
  "$ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com":
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
Description=Generates registries files from k3s api server and publishes to s3 every 6h
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
Description=Generates registries files from k3s api server and publishes to s3 every 6h
[Timer]
OnUnitActiveSec=6h
Unit=k3s-registries.service
[Install]
WantedBy=multi-user.target
EOM

    echo "activating registries script and systemd service+timer"
    systemctl daemon-reload
    systemctl enable k3s-registries.service k3s-registries.timer
    systemctl start k3s-registries.service k3s-registries.timer

fi
