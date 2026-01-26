#!/bin/bash
set -e

# Basic deps
apt-get update -y
apt-get install -y unzip curl jq

# Create vault user and dirs
useradd --system --home /srv/vault --shell /bin/false vault || true
mkdir -p /etc/vault.d /opt/vault/data
chown -R vault:vault /etc/vault.d /opt/vault

# Install Vault
VAULT_VERSION="1.21.0"
curl -sSLo /tmp/vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"
unzip /tmp/vault.zip -d /usr/local/bin
chmod +x /usr/local/bin/vault


# Vault config (integrated storage + AWS auto-join)
cluster_tag_key="vault-cluster"
cluster_tag_value="vault-prod-cluster"
cluster_name="vault-prod"
LOCAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
HOSTNAME=$(hostname)


cat <<EOT > /etc/vault.d/vault.hcl
ui = true
cluster_name="${cluster_name}"

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable     = 1
}

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "${HOSTNAME}"


  retry_join {
    auto_join = "provider=aws tag_key=${cluster_tag_key} tag_value=${cluster_tag_value} addr_type=private_v4"
  }
}

seal "awskms" {
  region = "us-east-1"
  kms_key_id = "arn:aws:kms:us-east-1:445567107707:key/9d1b7e9f-e793-48db-85a3-0366505eb640"
}

api_addr     = "http://${LOCAL_IP}:8200"
cluster_addr = "http://${LOCAL_IP}:8201"

disable_mlock = true
EOT

chown -R vault:vault /etc/vault.d /opt/vault

# Systemd service
cat <<EOT > /etc/systemd/system/vault.service 
[Unit]
Description=HashiCorp Vault
After=network-online.target
Wants=network-online.target

[Service]
User=vault
Group=vault
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOT

# Restart and enable vault service
systemctl daemon-reload
systemctl enable vault
systemctl start vault

