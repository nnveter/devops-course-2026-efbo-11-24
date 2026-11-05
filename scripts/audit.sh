#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
check() {
  if [[ "$2" == "$3" ]]; then printf '[OK] %s\n' "$1"; PASS=$((PASS+1));
  else printf '[FAIL] %s (expected=%s actual=%s)\n' "$1" "$2" "$3"; FAIL=$((FAIL+1)); fi
}
echo "Audit: $(hostname), $(date -Is)"
echo '[1] SSH'
settings=$(sudo sshd -T)
check 'Root login disabled' no "$(awk '/^permitrootlogin /{print $2}' <<<"$settings")"
check 'Password auth disabled' no "$(awk '/^passwordauthentication /{print $2}' <<<"$settings")"
check 'SSH port' 2222 "$(awk '/^port /{print $2}' <<<"$settings")"
check 'MaxAuthTries' 3 "$(awk '/^maxauthtries /{print $2}' <<<"$settings")"
echo '[2] Firewall'
check 'UFW active' active "$(sudo env LC_ALL=C ufw status | awk '/^Status:/{print $2}')"
check 'Default incoming deny' yes "$(sudo env LC_ALL=C ufw status verbose | grep -q 'Default: deny (incoming)' && echo yes)"
echo '[3] Accounts'
id devops
echo '[4] Nginx'
check 'Nginx active' active "$(systemctl is-active nginx)"
check 'Nginx syntax' 0 "$(sudo nginx -t >/dev/null 2>&1; echo $?)"
check 'Certificate lifetime >=30 days' 0 "$(openssl x509 -in /etc/ssl/certs/devops.crt -noout -checkend 2592000 >/dev/null; echo $?)"
check 'Website not world writable' '' "$(find /var/www/devops-site -perm -o+w)"
check 'TLS key permissions' 600 "$(sudo stat -c '%a' /etc/ssl/private/devops.key)"
echo '[5] Containers'
compose=(docker compose --project-directory "$HOME/devops-course-2026/app")
check 'Docker active' active "$(systemctl is-active docker)"
db=$("${compose[@]}" ps -q db)
check 'Postgres healthy' healthy "$(docker inspect -f '{{.State.Health.Status}}' "$db" 2>/dev/null)"
check 'App loopback only' '127.0.0.1:5000' "$("${compose[@]}" port app 5000)"
check 'Postgres not published' '{}' "$(docker inspect -f '{{json .HostConfig.PortBindings}}' "$db" 2>/dev/null)"
check 'Baseline app responds' yes "$(curl -fsS http://127.0.0.1:5000/health | grep -qx ok && echo yes)"
if [[ -f "$HOME/kr2/docker-compose.yml" ]]; then
  echo '[6] KR2'
  kr2=(docker compose --project-directory "$HOME/kr2")
  redis=$("${kr2[@]}" ps -q redis)
  check 'Redis healthy' healthy "$(docker inspect -f '{{.State.Health.Status}}' "$redis" 2>/dev/null)"
  check 'KR2 loopback only' '127.0.0.1:8003' "$("${kr2[@]}" port app 8003)"
  check 'Redis not published' '{}' "$(docker inspect -f '{{json .HostConfig.PortBindings}}' "$redis" 2>/dev/null)"
  check 'Secret permissions' 600 "$(stat -c '%a' "$HOME/kr2/.env")"
  check 'KR2 certificate >=30 days' 0 "$(openssl x509 -in /etc/ssl/certs/kr2.crt -noout -checkend 2592000 >/dev/null; echo $?)"
  check 'KR2 enabled symlink' yes "$(test -L /etc/nginx/sites-enabled/kr2 && echo yes)"
fi
echo "Passed: $PASS; failed: $FAIL"
[[ $FAIL -eq 0 ]]
