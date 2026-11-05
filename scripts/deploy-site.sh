#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ssh_command="ssh -p 2222 -i ${DEVOPS_KEY:-/tmp/devops_key} -o UserKnownHostsFile=${DEVOPS_KNOWN_HOSTS:-/tmp/known_hosts}"
rsync -avz --delete --chmod=D755,F644 --dry-run -e "$ssh_command" site/ devops@192.168.57.23:/var/www/devops-site/
rsync -avz --delete --chmod=D755,F644 -e "$ssh_command" site/ devops@192.168.57.23:/var/www/devops-site/
