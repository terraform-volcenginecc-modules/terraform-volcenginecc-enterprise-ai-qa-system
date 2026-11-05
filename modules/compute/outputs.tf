output "key_pair_name" {
  value       = var.login_mode == "key_pair" ? var.key_pair_name : null
  description = "key_pair 模式绑定的已有 ECS 密钥对名称；password 模式为 null"
}

output "instance_id" {
  value       = volcenginecc_ecs_instance.main.instance_id
  description = "ECS 实例 ID"
}

output "public_ip" {
  value       = volcenginecc_ecs_instance.main.eip_address.ip_address
  description = "ECS 公网 IP"
}

output "private_ip" {
  value       = volcenginecc_ecs_instance.main.primary_network_interface.primary_ip_address
  description = "ECS 私网 IP"
}

output "source_delivery" {
  description = "非敏感 cloud-init 交付信息"
  value = {
    sha256                = var.source_sha256
    encoded_userdata_size = length(volcenginecc_ecs_instance.main.user_data)
  }
}
