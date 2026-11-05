output "vpc_id" {
  value       = volcenginecc_vpc_vpc.main.id
  description = "VPC ID"
}

output "subnet_id" {
  value       = volcenginecc_vpc_subnet.main.id
  description = "子网 ID"
}

output "security_group_id" {
  value       = volcenginecc_vpc_security_group.app.id
  description = "应用安全组 ID"
}
