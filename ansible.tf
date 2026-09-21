locals {
  # Группа webservers
  webservers = [
    for vm in yandex_compute_instance.web : {
      name         = vm.name
      external_ip  = vm.network_interface[0].nat_ip_address
      fqdn         = vm.fqdn
    }
  ]

  # Группа databases
  databases = [
  for vm in yandex_compute_instance.db : {
    name         = vm.name
    external_ip  = coalesce(vm.network_interface[0].nat_ip_address, vm.network_interface[0].ip_address)
    fqdn         = vm.fqdn
  }
]


  # Группа storage
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

