variable "name_prefix" { type = string }
variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "tags_list" {
  type = list(object({
    key   = string
    value = string
  }))
}
