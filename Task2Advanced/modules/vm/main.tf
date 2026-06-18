data "yandex_compute_image" "boot" {
  family = var.boot_image_family
}

resource "yandex_compute_disk" "data_disk" {
  name = "${var.name}-data-disk"
  type = var.disk_type
  zone = var.zone
  size = var.disk_size
}

resource "yandex_compute_instance" "vm" {
  name        = var.name
  platform_id = var.platform_id
  zone        = var.zone

  resources {
    cores         = var.cores
    memory        = var.memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.boot.id
      size     = var.boot_disk_size
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_key}"
  }
}

resource "yandex_compute_instance_secondary_disk" "attachment" {
  instance_id = yandex_compute_instance.vm.id
  disk_id     = yandex_compute_disk.data_disk.id
}
