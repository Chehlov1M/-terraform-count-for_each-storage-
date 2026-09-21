resource "yandex_compute_disk" "extra_disks" {
  count       = 3
  name        = "disk-${count.index}"
  type        = "network-hdd"
  zone        = var.default_zone
  size        = 1
  description = "Disk for storage VM"
}

resource "yandex_compute_instance" "storage" {
  name   = "storage"
  zone   = var.default_zone
  platform_id = "standard-v1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      # Сюда вставь ID, который нашёл в Marketplace (начинается на fd8...)
      image_id = "fd808st5ai303d6i8f06"
    }
  }

  network_interface {
    subnet_id         = var.existing_subnet_id
    nat               = true
    security_group_ids = [var.security_group_id]
  }

  dynamic "secondary_disk" {
    for_each = yandex_compute_disk.extra_disks
    content {
      disk_id = secondary_disk.value.id
    }
  }

 metadata = {
    ssh-keys = "yc-user:${file("~/.ssh/id_ed25519.pub")}"
  }
}
