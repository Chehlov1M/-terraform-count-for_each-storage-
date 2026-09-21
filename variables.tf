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
  default     = "b1g5os3824accc9l84bg"
  description = "ID облака"
}

variable "folder_id" {
  type        = string
  default     = "b1gsn99obvku3uqt3j9o"
  description = "ID папки"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-b"
  description = "Зона доступности"
}

variable "service_account_key_file" {
  type        = string
  default     = "key.json"
  description = "Путь к ключу сервисного аккаунта"
}

variable "existing_subnet_id" {
  type        = string
  default     = "e2lfmpn285qj1fk0i3n3"
  description = "ID существующей подсети"
}

variable "security_group_id" {
  type        = string
  default     = "enpqu8a2rk2sndkob9be"
  description = "ID группы безопасности"
}

variable "vms_ssh_root_key" {
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL14BVYJHDq6YQWdaA8uAOAFD74JhA1ptOUOOz4FAH// your_email@example.com"
  description = "SSH-ключ"
}


