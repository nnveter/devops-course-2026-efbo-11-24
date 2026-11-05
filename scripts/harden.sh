#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/ssh/sshd_config.d/00-devops-hardening.conf >/dev/null <<'EOF'
Port 2222
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
AllowUsers devops
EOF
sudo sshd -t
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit 2222/tcp comment 'SSH rate-limited'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw --force enable
sudo systemctl restart ssh
sudo sshd -T | grep -E '^(port|permitrootlogin|passwordauthentication|maxauthtries) '
sudo ufw status verbose
