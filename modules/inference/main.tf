###############################################################################
# inference 模块
# 创建豆包生成模型和文本向量模型两个方舟 Endpoint，或复用已有 Endpoint。
# 推理使用用户通过敏感参数提供的方舟 API Key。
###############################################################################

resource "volcenginecc_ark_endpoint" "llm" {
  count        = var.create_endpoints ? 1 : 0
  name         = "${var.name_prefix}-llm"
  description  = "Doubao LLM endpoint for the RAG answer stage"
  project_name = var.project_name

  model_reference = {
    foundation_model = {
      name          = var.llm_foundation_model
      model_version = var.llm_model_version
    }
  }

  moderation = {
    strategy = var.moderation_strategy
  }

  tags = var.tags_list
}

resource "volcenginecc_ark_endpoint" "embedding" {
  count        = var.create_endpoints ? 1 : 0
  name         = "${var.name_prefix}-embedding"
  description  = "Doubao multimodal embedding endpoint for document and query vectors"
  project_name = var.project_name

  model_reference = {
    foundation_model = {
      name          = var.embedding_foundation_model
      model_version = var.embedding_model_version
    }
  }

  tags = var.tags_list
}

resource "terraform_data" "endpoint_selection" {
  input = var.create_endpoints
  lifecycle {
    precondition {
      condition     = var.create_endpoints || (can(regex("^ep-[a-z0-9-]+$", var.llm_endpoint_id)) && can(regex("^ep-[a-z0-9-]+$", var.embedding_endpoint_id)))
      error_message = "复用模式必须填写有效的 LLM 和 Embedding Endpoint ID。"
    }
    precondition {
      condition     = !var.create_endpoints || (var.llm_endpoint_id == "" && var.embedding_endpoint_id == "")
      error_message = "创建新 Endpoint 时请清空现有 Endpoint ID，避免配置歧义。"
    }
  }
}
