variable "name_prefix" { type = string }
variable "project_name" { type = string }
variable "zone_id" { type = string }
variable "vpc_cidr" { type = string }
variable "subnet_cidr" { type = string }
variable "ssh_source_cidr" { type = string }
variable "web_source_cidr" { type = string }
variable "tags_list" {
  type = list(object({
    key   = string
    value = string
  }))
}
