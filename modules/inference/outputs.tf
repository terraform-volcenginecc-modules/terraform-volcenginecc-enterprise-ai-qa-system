output "llm_endpoint_id" {
  value       = var.create_endpoints ? volcenginecc_ark_endpoint.llm[0].endpoint_id : var.llm_endpoint_id
  description = "豆包 LLM Endpoint ID"
}

output "embedding_endpoint_id" {
  value       = var.create_endpoints ? volcenginecc_ark_endpoint.embedding[0].endpoint_id : var.embedding_endpoint_id
  description = "Embedding Endpoint ID"
}
