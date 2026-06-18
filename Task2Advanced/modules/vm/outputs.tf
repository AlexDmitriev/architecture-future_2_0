output "vm_id" {
  description = "Created VM id"
  value       = yandex_compute_instance.vm.id
}

output "vm_name" {
  description = "Created VM name"
  value       = yandex_compute_instance.vm.name
}

output "internal_ip" {
  description = "Internal IP address"
  value       = yandex_compute_instance.vm.network_interface[0].ip_address
}

output "external_ip" {
  description = "External NAT IP address"
  value       = yandex_compute_instance.vm.network_interface[0].nat_ip_address
}

output "disk_id" {
  description = "Attached additional disk id"
  value       = yandex_compute_disk.data_disk.id
}
