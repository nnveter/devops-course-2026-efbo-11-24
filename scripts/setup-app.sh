#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../app"
if [[ ! -f .env ]]; then
  (umask 077; printf 'POSTGRES_DB=app\nPOSTGRES_USER=app\nPOSTGRES_PASSWORD=%s\nDB_HOST=db\n' "$(openssl rand -hex 24)" > .env)
fi
docker compose up -d --build --wait
docker compose ps
curl -fsS http://127.0.0.1:5000/
curl --resolve devops.local:443:127.0.0.1 --cacert ~/devops.crt -fsS https://devops.local/app/
chmod +x ../scripts/*.sh
../scripts/audit.sh
