# Task1Advanced: универсальный Terraform-модуль VM

## Структура

- `modules/vm/` — универсальный модуль ВМ
  - `main.tf` — VM + дополнительный диск + сеть
  - `variables.tf` — параметры модуля
  - `outputs.tf` — выходные значения
- `envs/dev/` — конфиг окружения dev
- `envs/stage/` — конфиг окружения stage
- `envs/prod/` — конфиг окружения prod

## Что делает модуль

Модуль `modules/vm` создаёт:

1. VM (`yandex_compute_instance`)
2. Дополнительный диск (`yandex_compute_disk`)
3. Подключение диска к VM (`yandex_compute_instance_secondary_disk`)
4. Сетевой интерфейс VM в указанной подсети (`subnet_id`)

## Входные параметры модуля

Обязательные:

- `name` — имя ВМ
- `zone` — зона размещения
- `cores` — количество ядер
- `memory` — RAM (GB)
- `disk_size` — размер подключаемого диска (GB)
- `subnet_id` — ID подсети
- `ssh_key` — публичный SSH-ключ

Опциональные (со значениями по умолчанию):

- `platform_id` (default: `standard-v1`)
- `core_fraction` (default: `100`)
- `boot_image_family` (default: `ubuntu-2204-lts`)
- `boot_disk_size` (default: `20`)
- `disk_type` (default: `network-hdd`)

## Выходы модуля

- `vm_id` — ID виртуальной машины
- `vm_name` — имя виртуальной машины
- `internal_ip` — внутренний IP
- `external_ip` — внешний IP (NAT)
- `disk_id` — ID подключаемого диска

## Как запускать

Перед запуском надо поставить реальные значения в `terraform.tfvars` (минимум `subnet_id` и `ssh_key`).

### dev

```bash
cd envs/dev
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### stage

```bash
cd envs/stage
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### prod

```bash
cd envs/prod
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```