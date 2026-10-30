locals {
  # 平台字符串输入框可能提交空字符串；统一视为未提供凭据，实际值保持不变。
  ecs_key_pair_name  = var.key_pair_name == null ? null : (trimspace(var.key_pair_name) == "" ? null : var.key_pair_name)
  ecs_login_password = var.ecs_password == null ? null : (trimspace(var.ecs_password) == "" ? null : var.ecs_password)

  tags_list = [for key, value in var.common_tags : {
    key   = key
    value = value
  }]
  runtime_config = {
    postgres_instance_id    = module.database.instance_id
    postgres_private_domain = module.database.private_domain
    postgres_private_port   = module.database.private_port
    postgres_database_name  = module.database.database_name
    postgres_admin_username = var.postgres_admin_username
    postgres_admin_password = var.postgres_admin_password
    ark_base_url            = var.ark_base_url == "" ? "https://ark.${var.region}.volces.com/api/v3" : var.ark_base_url
    ark_api_key             = var.ark_api_key
    llm_endpoint_id         = module.inference.llm_endpoint_id
    embedding_endpoint_id   = module.inference.embedding_endpoint_id
    embedding_dimensions    = var.embedding_dimensions
    chunk_size              = var.chunk_size
    chunk_overlap           = var.chunk_overlap
    default_top_k           = var.default_top_k
    max_upload_bytes        = var.max_upload_bytes
    max_cosine_distance     = var.max_cosine_distance
  }
}
