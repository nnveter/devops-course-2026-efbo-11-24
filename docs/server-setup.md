# Учебный сервер

Сальников Илья Андреевич, ЭФБО-11-24, №23.

## Виртуальная машина

VirtualBox `devops-vm-salnikov`; Ubuntu Server 22.04.5 LTS; 4 ГБ ОЗУ;
1 vCPU; динамический VDI 32 ГБ.

Каталог Windows: `F:\temp\devops\infrastructure\vms\devops-vm-salnikov`.
Ubuntu Cloud Image от 25.10.2026 проверен по официальному SHA256.

Первоначально использовались 4 vCPU и KVM paravirtualization. При работе
VirtualBox поверх Windows Hyper-V загрузка была нестабильной. Рабочая
конфигурация: 1 vCPU, paravirtualization none, контроллер VBoxSVGA.

## Сеть

- enp0s3: NAT, DHCP `10.0.2.15` — выход в Интернет.
- enp0s8: Host-only `192.168.57.23/24`; Windows `192.168.57.1`.
- Выделенный адаптер `VirtualBox Host-Only Ethernet Adapter #2`.
- Windows hosts: `192.168.57.23 devops.local stats.devops.local`.
- Временный NAT-проброс 127.0.0.1:2223 → guest:22 использовался только
  при диагностике начальной загрузки; окончательный доступ — Host-only:2222.

## Пользователь и SSH

`devops`, группы sudo и docker; отдельный ключ Ed25519 хранится на Windows
в `F:\temp\devops\.private\devops_ed25519` (не публикуется).

```powershell
ssh -p 2222 -i F:\temp\devops\.private\devops_ed25519 devops@192.168.57.23
```

Сервер: `/etc/ssh/sshd_config.d/00-devops-hardening.conf`:
Port 2222, PermitRootLogin no, PasswordAuthentication no,
KbdInteractiveAuthentication no, MaxAuthTries 3, AllowUsers devops.

## Межсетевой экран

UFW: deny incoming, allow outgoing; limit 2222/tcp, allow 80/tcp,
allow 443/tcp. Для контейнеров новые разрешающие правила не добавляются.

## Веб-ресурсы

- `/var/www/devops-site` — статический сайт, владелец devops.
- `/etc/nginx/sites-available/devops-site` — HTTP redirect и HTTPS,
  `/app/` проксируется на `127.0.0.1:5000`.
- `/etc/ssl/certs/devops.crt` — публичный сертификат SAN devops.local.
- `/etc/ssl/private/devops.key` — root:root 600.
- Отдельный ресурс KR2: `stats.devops.local` → `127.0.0.1:8003`.

## Контейнеры

`~/devops-course-2026/app`: Flask + PostgreSQL 16, порт приложения 5000
только loopback, БД не опубликована, том db_data.
`~/kr2`: Flask + Redis 7, порт 8003 только loopback, Redis не опубликован,
том redis_data. Перезапуск unless-stopped, готовность зависимостей проверяется.
Секреты .env создаются только на VM с правами 600.

## Воспроизведение

Сначала подготовить Ubuntu и SSH-ключ через cloud-init. Далее доставить проект:
`bootstrap.sh`, `harden.sh`, `setup-web.sh`, `setup-app.sh`.
После установки Docker переподключиться, чтобы применилось членство в группе.
Работоспособность: `scripts/audit.sh` (код 0).

Контрольные снимки: 01-clean-install, 02-keys-configured, 03-ssh-hardened,
04-nginx-https, 05-docker-compose, 06-before-kr2, 07-kr2.

## Ansible

Контроллер запускается в отдельном Linux-контейнере на Windows.
Ключ монтируется только на время запуска, никогда не включается в образ.
Роли base, nginx, app, ssh выполняются последовательно и имеют одноимённые теги.
До запуска собрать `site.tar.gz` с файлами сайта (0644).
Требуется коллекция ansible.posix 2.1.0.

```sh
cd ansible
ansible-playbook setup.yml --syntax-check
ansible-playbook setup.yml
ansible-playbook setup.yml --tags app
```
