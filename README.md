# DevOps-практикум — ЭФБО-11-24

**Сальников Илья Андреевич**, №23 по списку.

- [КР №1](https://github.com/nnveter/devops-kr1-efbo-11-24)
- [КР №2, вариант 3](https://github.com/nnveter/devops-kr2-efbo-11-24/pull/1)
- [GitHub Pages](https://nnveter.github.io/)
- [Конфигурация VM](docs/server-setup.md)

## Структура

- `site/` — статический сайт (HTML, CSS, SVG).
- `scripts/deploy-site.sh` — rsync dry-run и доставка по SSH.
- `ansible/` — setup.yml, inventory.ini, роли base/nginx/app/ssh.
- `app/` — приложение ПР №7 с PostgreSQL.
- `nginx/` — основной HTTPS virtual host.
- `scripts/audit.sh` — 22 проверки состояния сервера, включая КР №2.

Секреты, закрытые ключи и файлы виртуальной машины в репозиторий не входят.

## Проверенные результаты КР №3

- GitHub Pages успешно опубликован workflow `deploy.yml`.
- rsync выполнен сначала с `--dry-run`, затем с реальной доставкой.
- Ansible: первый запуск `ok=13 changed=5 failed=0`.
- Повторный запуск: `ok=12 changed=0 failed=0` — идемпотентность подтверждена.
- `--tags app`: `ok=2 changed=0 failed=0`.
- После автоматизации аудит сервера проходит 22/22 проверки.

Перед Ansible сформировать архив: `python3 scripts/package-site.py`.
Контроллеру нужны `ansible-core==2.19.3` и коллекции из `ansible/requirements.yml`.
