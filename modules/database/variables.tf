variable "name_prefix" { type = string }
variable "project_name" { type = string }
variable "zone_id" { type = string }
variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "subnet_cidr" { type = string }
variable "db_engine_version" { type = string }
variable "node_spec" { type = string }
variable "storage_space_gb" { type = number }
variable "database_name" { type = string }
variable "admin_username" { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}
variable "tags_list" {
  type = list(object({
    key   = string
    value = string
  }))
}
