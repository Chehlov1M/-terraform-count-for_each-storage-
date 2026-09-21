locals {
  ssh_public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))

  vm_metadata = {
    serial-port-enable = "1"
    ssh-keys = "ubuntu:${local.ssh_public_key}"
  }
}

