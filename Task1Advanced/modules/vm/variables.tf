variable "name" {
  description = "VM name"
  type        = string
}

variable "zone" {
  description = "Availability zone"
  type        = string
}

variable "cores" {
  description = "Number of vCPU cores"
  type        = number
}

variable "memory" {
  description = "RAM size in GB"
  type        = number
}

variable "disk_size" {
  description = "Additional disk size in GB"
  type        = number
}

variable "subnet_id" {
  description = "Subnet ID to attach VM network interface"
  type        = string
}

variable "ssh_key" {
  description = "SSH public key content"
  type        = string
}

variable "platform_id" {
  description = "VM platform id"
  type        = string
  default     = "standard-v1"
}

variable "core_fraction" {
  description = "Guaranteed CPU fraction"
  type        = number
  default     = 100
}

variable "boot_image_family" {
  description = "Boot image family"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Additional disk type"
  type        = string
  default     = "network-hdd"
}
