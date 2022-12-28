#!/bin/bash

# oidc (irsa)

echo "generating oidc script and systemd service+timer"
tee /usr/local/bin/oidc >/dev/null << EOM
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

tee /etc/systemd/system/k3s-oidc.service >/dev/null << EOM
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

tee /etc/systemd/system/k3s-oidc.timer >/dev/null << EOM
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
