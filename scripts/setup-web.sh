#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
sudo openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout /etc/ssl/private/devops.key -out /etc/ssl/certs/devops.crt \
  -subj '/CN=devops.local' -addext 'subjectAltName=DNS:devops.local'
sudo chmod 600 /etc/ssl/private/devops.key
sudo install -m 644 nginx/devops-site /etc/nginx/sites-available/devops-site
sudo ln -sfn /etc/nginx/sites-available/devops-site /etc/nginx/sites-enabled/devops-site
rsync -av --delete --chmod=D755,F644 site/ /var/www/devops-site/
sudo nginx -t
sudo systemctl reload nginx
cp /etc/ssl/certs/devops.crt ~/devops.crt
curl --resolve devops.local:443:127.0.0.1 --cacert ~/devops.crt -I https://devops.local/
