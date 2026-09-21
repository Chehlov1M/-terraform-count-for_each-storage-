data "yandex_compute_image" "ubuntu_for_each" {
  family = "ubuntu-2004-lts"
}

resource "yandex_compute_instance" "db" {
  for_each = { for vm in var.each_vm : vm.vm_name => vm }

  name        = each.value.vm_name
  platform_id = "standard-v1"
  zone        = var.default_zone

  scheduling_policy {
    preemptible = true
  }

  resources {
    cores         = each.value.cpu
    memory        = each.value.ram
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_for_each.id
      size     = each.value.disk_volume
    }
  }

  network_interface {
    subnet_id          = var.existing_subnet_id
    nat                = false
    security_group_ids = [var.security_group_id]
  }

  metadata = local.vm_metadata
}

