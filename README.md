ansible.tf:
```hcl
locals {

  webservers = [
    for vm in yandex_compute_instance.web : {
      name         = vm.name
      external_ip  = vm.network_interface[0].nat_ip_address
      fqdn         = vm.fqdn
    }
  ]


  databases = [
  for vm in yandex_compute_instance.db : {
    name         = vm.name
    external_ip  = coalesce(vm.network_interface[0].nat_ip_address, vm.network_interface[0].ip_address)
    fqdn         = vm.fqdn
  }
]


 
  storage = [
    for vm in [yandex_compute_instance.storage] : {
      name         = vm.name
      external_ip  = vm.network_interface[0].nat_ip_address
      fqdn         = vm.fqdn
    }
  ]
}

resource "terraform_data" "ansible_inventory" {
  input = templatefile("inventory.tpl", {
    webservers = local.webservers
    databases  = local.databases
    storage    = local.storage
  })

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      cat <<'INVENTORY_EOF' > inventory
      ${self.input}
      INVENTORY_EOF
    EOT
  }
}
```

locals.tf:
```hcl
locals {
  ssh_public_key = file(pathexpand("~/.ssh/id_.pub"))

  vm_metadata = {
    serial-port-enable = "1"
    ssh-keys = "ubuntu:${local.ssh_public_key}"
  }
}
```

main.tf:
```hcl
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.80.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
}
```

variables.tf:
```hcl
variable "each_vm" {
  type = list(object({
    vm_name     = string
    cpu         = number
    ram         = number
    disk_volume = number
  }))
  default = [
    {
      vm_name     = "main"
      cpu         = 2
      ram         = 2
      disk_volume = 5
    },
    {
      vm_name     = "replica"
      cpu         = 4
      ram         = 4
      disk_volume = 10
    }
  ]
  description = "Параметры ВМ для баз данных (создаются через for_each)"
}

variable "cloud_id" {
  type        = string
  default     = ""
  description = "ID облака"
}

variable "folder_id" {
  type        = string
  default     = ""
  description = "ID папки"
}

variable "default_zone" {
  type        = string
  default     = ""
  description = "Зона доступности"
}

variable "service_account_key_file" {
  type        = string
  default     = "key.json"
  description = "Путь к ключу сервисного аккаунта"
}

variable "existing_subnet_id" {
  type        = string
  default     = ""
  description = "ID существующей подсети"
}

variable "security_group_id" {
  type        = string
  default     = ""
  description = "ID группы безопасности"
}

variable "vms_ssh_root_key" {
  type        = string
  default     = "ssh"
  description = "SSH-ключ"
}
```

terraform.tfvars:
```hcl
cloud_id        = ""
folder_id       = ""
default_zone    = ""
```

count-vm.tf:
```hcl
resource "yandex_compute_instance" "web" {
  count = 2

  name        = "web-${count.index + 1}"
  platform_id = "standard-v1"
  zone        = var.default_zone

  depends_on = [yandex_compute_instance.db]

  scheduling_policy {
    preemptible = true
  }

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_for_each.id
      size     = 5
    }
  }

  network_interface {
    subnet_id          = var.existing_subnet_id
    nat                = true
    security_group_ids = [var.security_group_id]
  }

  metadata = local.vm_metadata
}
```

for_each-vm.tf:
```hcl
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
```

disk_vm.tf:
```hcl
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
      image_id = ""
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
    ssh-keys = "yc-user:${file("~/.ssh/id_")}"
  }
}
```

inventory.tpl:
```hcl
[webservers]
%{ for vm in webservers ~}
${vm.name} ansible_host=${vm.external_ip} fqdn=${vm.fqdn}
%{ endfor ~}

[databases]
%{ for vm in databases ~}
${vm.name} ansible_host=${vm.external_ip} fqdn=${vm.fqdn}
%{ endfor ~}

[storage]
%{ for vm in storage ~}
${vm.name} ansible_host=${vm.external_ip} fqdn=${vm.fqdn}
%{ endfor ~}




