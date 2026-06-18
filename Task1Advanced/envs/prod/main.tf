terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.120.0"
    }
  }
}

provider "yandex" {
  zone = var.zone
}

module "vm" {
  source = "../../modules/vm"

  name      = var.name
  zone      = var.zone
  cores     = var.cores
  memory    = var.memory
  disk_size = var.disk_size
  subnet_id = var.subnet_id
  ssh_key   = var.ssh_key
}

output "vm_id" {
  value = module.vm.vm_id
}

output "external_ip" {
  value = module.vm.external_ip
}
