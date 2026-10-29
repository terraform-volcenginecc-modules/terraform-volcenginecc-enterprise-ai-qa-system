output "source_url" {
  value       = split("?", volcenginecc_tos_object.source.url)[0]
  description = "公开源码对象下载地址；移除 Provider 可能返回的预签名参数"
}

output "source_sha256" {
  value       = local.payload_sha256
  description = "解压后应用源码清单 SHA-256"
}

output "bucket_name" {
  value       = volcenginecc_tos_bucket.source.name
  description = "应用源码交付桶名称"
}

output "encoded_payload_size" {
  value       = length(local.payload_base64)
  description = "TOS 文本对象内容字节数"
}
