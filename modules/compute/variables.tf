variable "name_prefix" { type = string }
variable "project_name" { type = string }
variable "zone_id" { type = string }
variable "subnet_id" { type = string }
variable "security_group_id" { type = string }
variable "image_id" { type = string }
variable "instance_type" { type = string }
variable "login_mode" { type = string }
variable "key_pair_name" {
  type     = string
  nullable = true
}
variable "password" {
  type      = string
  nullable  = true
  sensitive = true
}
variable "public_bandwidth_mbps" { type = number }
variable "system_disk_size_gb" { type = number }
variable "runtime_config" { type = any }
variable "source_url" { type = string }
variable "source_sha256" { type = string }
variable "tags_list" {
  type = list(object({
    key   = string
    value = string
  }))
}
