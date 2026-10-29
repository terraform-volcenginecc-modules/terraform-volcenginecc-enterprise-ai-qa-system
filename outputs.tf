output "web_url" {
  description = "RAG Web HTTP 地址（Apply 后等待 ECS 自动安装完成）"
  value       = "http://${module.compute.public_ip}/"
}

output "ecs_public_ip" {
  description = "ECS 公网 IP"
  value       = module.compute.public_ip
}

output "ecs_private_ip" {
  description = "ECS 私网 IP"
  value       = module.compute.private_ip
}

output "postgres_instance_id" {
  description = "RDS PostgreSQL 实例 ID"
  value       = module.database.instance_id
}

output "postgres_private_domain" {
  description = "RDS PostgreSQL 私网域名"
  value       = module.database.private_domain
}

output "postgres_private_port" {
  description = "RDS PostgreSQL 私网端口"
  value       = module.database.private_port
}

output "postgres_database_name" {
  description = "RAG 数据库名称"
  value       = module.database.database_name
}

output "llm_endpoint_id" {
  description = "豆包 LLM 方舟 Endpoint ID"
  value       = module.inference.llm_endpoint_id
}

output "embedding_endpoint_id" {
  description = "Embedding 方舟 Endpoint ID"
  value       = module.inference.embedding_endpoint_id
}

output "embedding_dimensions" {
  description = "应用与 pgvector 使用的向量维度"
  value       = var.embedding_dimensions
}

output "ecs_instance_id" {
  description = "ECS 实例 ID，供运维使用"
  value       = module.compute.instance_id
}

output "ecs_login_mode" {
  value       = var.ecs_login_mode
  description = "ECS 登录模式：key_pair 或 password"
}

output "ecs_key_pair_name" {
  value       = module.compute.key_pair_name
  description = "key_pair 模式绑定的已有 ECS 密钥对名称"
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "subnet_id" {
  value = module.network.subnet_id
}

output "security_group_id" {
  value = module.network.security_group_id
}

output "runtime_config" {
  description = "部署脚本使用的非敏感配置，不包含任何密码或 API Key"
  value = {
    region               = var.region
    ark_base_url         = var.ark_base_url == "" ? "https://ark.${var.region}.volces.com/api/v3" : var.ark_base_url
    chunk_size           = var.chunk_size
    chunk_overlap        = var.chunk_overlap
    default_top_k        = var.default_top_k
    max_upload_bytes     = var.max_upload_bytes
    max_cosine_distance  = var.max_cosine_distance
    embedding_dimensions = var.embedding_dimensions
  }
}

output "deployment_next_step" {
  value = "等待 ECS /opt/rag-qa-deploy/STATUS 为 ready；通过 ECS 终端 sudo 读取 .runtime/secrets.json 的 web_username/web_password，然后打开 web_url。"
}

output "source_bucket_name" {
  value       = module.delivery.bucket_name
  description = "无秘密应用源码交付使用的 TOS Bucket"
}
