# Task2Advanced: Terraform + remote state + GitLab CI/CD

Проект автоматизирует развёртывание инфраструктуры через GitLab Pipelines.  
Состояние Terraform хранится **только удалённо** в S3-совместимом хранилище (AWS S3, Yandex Object Storage, MinIO). Локальные `terraform.tfstate` в репозиторий не попадают.

## Структура

```text
Task2Advanced/
├── .gitlab-ci.yml          # Pipeline: validate → plan → apply (manual)
├── .gitignore              # Исключает state, secrets, plan-артефакты
├── modules/vm/             # Переиспользуемый модуль ВМ
├── scripts/
│   ├── terraform-init.sh   # init с remote backend из переменных окружения
│   ├── terraform-plan.sh   # plan с сохранением plan.tfplan
│   └── terraform-apply.sh  # apply сохранённого плана
└── envs/
    ├── dev/
    ├── stage/
    └── prod/
```

Каждое окружение изолировано:

| Окружение | State key в bucket        |
|-----------|---------------------------|
| dev       | `dev/terraform.tfstate`   |
| stage     | `stage/terraform.tfstate` |
| prod      | `prod/terraform.tfstate`  |

## Remote backend

В каждом окружении `backend.tf` содержит partial-конфигурацию:

```hcl
terraform {
  backend "s3" {}
}
```

Параметры bucket/key/region/endpoint **не захардкожены** в коде. Они передаются:

- в CI/CD — через переменные окружения и скрипт `scripts/terraform-init.sh`;
- локально — через `backend-config.hcl` (файл в `.gitignore`, пример: `backend-config.example.hcl`).

### Поддерживаемые хранилища

**AWS S3** — достаточно `bucket`, `key`, `region`.

**Yandex Object Storage** — дополнительно:

```hcl
endpoint                    = "https://storage.yandexcloud.net"
skip_region_validation      = true
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_requesting_account_id  = true
```

**MinIO** — как Yandex, плюс:

```hcl
use_path_style = true
```

### Аутентификация к backend

Ключи доступа передаются только через переменные окружения (не в git):

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

Для Yandex Object Storage используются статические ключи сервисного аккаунта с правами на bucket.

## Скрипты

### `scripts/terraform-init.sh`

Инициализирует Terraform с удалённым backend.

```bash
./scripts/terraform-init.sh envs/dev
```

Обязательные переменные:

| Переменная              | Описание                    |
|-------------------------|-----------------------------|
| `TF_BACKEND_BUCKET`     | Имя bucket                  |
| `TF_BACKEND_KEY`        | Путь к state-файлу в bucket |
| `TF_BACKEND_REGION`     | Регион                      |
| `AWS_ACCESS_KEY_ID`     | Access key для S3 API       |
| `AWS_SECRET_ACCESS_KEY` | Secret key для S3 API       |

Опциональные:

| Переменная                  | Описание                  |
|-----------------------------|---------------------------|
| `TF_BACKEND_ENDPOINT`       | Endpoint для Yandex/MinIO |
| `TF_BACKEND_USE_PATH_STYLE` | `true` для MinIO          |

Скрипт создаёт временный backend-config, выполняет `terraform init -reconfigure` и удаляет файл.

### `scripts/terraform-plan.sh`

Строит план и сохраняет его в `plan.tfplan`.

```bash
./scripts/terraform-plan.sh envs/dev
```

Если существует `terraform.tfvars`, подключает его автоматически.  
Секреты можно передать через `TF_VAR_*`:

```bash
export TF_VAR_subnet_id="e9b..."
export TF_VAR_ssh_key="ssh-rsa AAAA..."
./scripts/terraform-plan.sh envs/dev
```

### `scripts/terraform-apply.sh`

Применяет ранее сохранённый план (без интерактивного подтверждения).

```bash
./scripts/terraform-apply.sh envs/dev plan.tfplan
```

Отдельный шаг apply нужен для ручного approval в GitLab CI.

## Локальный запуск (без локального state)

```bash
cd Task2Advanced

# 1. Скопировать примеры
cp envs/dev/terraform.tfvars.example envs/dev/terraform.tfvars
cp envs/dev/backend-config.example.hcl envs/dev/backend-config.hcl

# 2. Заполнить terraform.tfvars и backend-config.hcl

# 3. Экспортировать ключи
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export YC_TOKEN="..."
export YC_CLOUD_ID="..."
export YC_FOLDER_ID="..."

# 4. Init / plan / apply через скрипты
export TF_BACKEND_BUCKET="terraform-state-bucket"
export TF_BACKEND_KEY="dev/terraform.tfstate"
export TF_BACKEND_REGION="ru-central1"
export TF_BACKEND_ENDPOINT="https://storage.yandexcloud.net"  # при необходимости

./scripts/terraform-init.sh envs/dev
./scripts/terraform-plan.sh envs/dev
./scripts/terraform-apply.sh envs/dev plan.tfplan
```

После `init` в каталоге окружения остаётся только `.terraform/` (кэш провайдеров), **не** `terraform.tfstate`.

## GitLab CI/CD

Файл: `.gitlab-ci.yml`

### Настройка проекта

1. В GitLab: **Settings → CI/CD → General pipelines** укажите путь к конфигу:  
   `Task2Advanced/.gitlab-ci.yml`
2. Добавьте CI/CD Variables (masked + protected для prod):

| Variable                | Masked | Protected | Назначение            |
|-------------------------|--------|-----------|-----------------------|
| `AWS_ACCESS_KEY_ID`     | yes    | yes       | Доступ к state bucket |
| `AWS_SECRET_ACCESS_KEY` | yes    | yes       | Доступ к state bucket |
| `YC_TOKEN`              | yes    | yes       | Yandex Cloud API      |
| `YC_CLOUD_ID`           | no     | yes       | Cloud ID              |
| `YC_FOLDER_ID`          | no     | yes       | Folder ID             |
| `TF_VAR_subnet_id`      | no     | per env   | Subnet для ВМ         |
| `TF_VAR_ssh_key`        | yes    | per env   | SSH public key        |

При необходимости переопределите в GitLab:

- `TF_BACKEND_BUCKET`
- `TF_BACKEND_REGION`
- `TF_BACKEND_ENDPOINT`
- `TF_BACKEND_USE_PATH_STYLE`

### Стадии pipeline

1. **validate** — `terraform fmt -check`, `terraform validate` (без backend).
2. **plan** — `terraform init` + `terraform plan`, артефакт `plan.tfplan`.
3. **apply** — `when: manual`, применяет план после нажатия кнопки в GitLab.

### Изоляция окружений

- Отдельный state key для `dev`, `stage`, `prod`.
- `plan:prod` и `apply:prod` запускаются только на default branch.
- `apply:*` — только вручную (`when: manual`).
- `apply:prod` использует `needs` к соответствующему `plan:prod`.

## Безопасность

- Секреты не хранятся в репозитории (`terraform.tfvars`, `backend-config.hcl` в `.gitignore`).
- Чувствительные Terraform-переменные помечены `sensitive = true`.
- Backend-config генерируется во временный файл и удаляется после `init`.
- Plan-артефакты могут содержать чувствительные данные — срок хранения 1 неделя.
- Для production используйте protected branches и protected CI variables.
- Выдавайте сервисному аккаунту минимальные права: только нужный bucket/prefix.

## Модуль `modules/vm`

Параметры и outputs совпадают с Task1Advanced. Окружения отличаются только значениями в `terraform.tfvars` и state key в backend.
