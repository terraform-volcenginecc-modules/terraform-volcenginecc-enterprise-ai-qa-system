output "instance_id" {
  value       = volcenginecc_rdspostgresql_instance.main.instance_id
  description = "RDS PostgreSQL 实例 ID"
}

output "database_name" {
  value       = volcenginecc_rdspostgresql_database.rag.db_name
  description = "RAG 数据库名称"
}

output "allow_list_id" {
  value       = volcenginecc_rdspostgresql_allow_list.app_subnet.allow_list_id
  description = "应用子网白名单 ID"
}

output "private_domain" {
  value       = local.private_addresses[0].domain
  description = "RDS PostgreSQL 私网域名"
}

output "private_port" {
  value       = local.private_addresses[0].port
  description = "RDS PostgreSQL 私网端口"
}
