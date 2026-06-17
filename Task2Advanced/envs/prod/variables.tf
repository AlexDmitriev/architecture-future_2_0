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
  description = "Subnet ID"
  type        = string
}

variable "ssh_key" {
  description = "SSH public key"
  type        = string
  sensitive   = true
}
