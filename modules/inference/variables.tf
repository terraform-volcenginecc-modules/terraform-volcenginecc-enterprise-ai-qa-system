variable "name_prefix" { type = string }
variable "create_endpoints" { type = bool }
variable "llm_endpoint_id" { type = string }
variable "embedding_endpoint_id" { type = string }
variable "project_name" { type = string }
variable "llm_foundation_model" { type = string }
variable "llm_model_version" { type = string }
variable "embedding_foundation_model" { type = string }
variable "embedding_model_version" { type = string }
variable "moderation_strategy" { type = string }
variable "tags_list" {
  type = list(object({
    key   = string
    value = string
  }))
}
