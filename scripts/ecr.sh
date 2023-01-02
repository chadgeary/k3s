#!/bin/bash

echo "INFO: Installing ecr auth script"

# ecr (registries)
if [ "$K3S_NODEGROUP" == "control-plane" ]; then
  K3S_SYSTEMD_UNIT="k3s.service"
  export K3S_SYSTEMD_UNIT
else
  K3S_SYSTEMD_UNIT="k3s-agent.service"
  export K3S_SYSTEMD_UNIT
fi

echo "INFO: generating registries script and systemd service+timer"
tee /usr/local/bin/registries >/dev/null << EOM
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
systemctl restart $K3S_SYSTEMD_UNIT

EOM
chmod 700 /usr/local/bin/registries

tee /etc/systemd/system/k3s-registries.service >/dev/null << EOM
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

tee /etc/systemd/system/k3s-registries.timer >/dev/null << EOM
[Unit]
Description=Generates registries files from k3s api server and publishes to s3 every 11h
[Timer]
OnUnitActiveSec=11h
Unit=k3s-registries.service
[Install]
WantedBy=multi-user.target
EOM

echo "INFO: activating registries script and systemd service+timer"
systemctl daemon-reload
systemctl enable k3s-registries.service k3s-registries.timer
systemctl start k3s-registries.service k3s-registries.timer
