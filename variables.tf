variable "region" {
  type        = string
  description = "火山引擎地域"
  default     = "cn-beijing"
}

variable "zone_id" {
  type        = string
  description = "部署 ECS 与 RDS PostgreSQL 的可用区"
  default     = "cn-beijing-a"
}

variable "project_name" {
  type        = string
  description = "火山引擎项目名称"
  default     = "default"
}

variable "name_prefix" {
  type        = string
  description = "资源名称前缀"
  default     = "enterprise-ai-qa"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.name_prefix))
    error_message = "资源前缀须为 3–31 位小写字母、数字或连字符，并以字母开头。"
  }
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.40.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "应用与数据库子网 CIDR"
  default     = "10.40.1.0/24"
}

variable "ssh_source_cidr" {
  type        = string
  description = "允许 SSH 22 的 IPv4 来源；支持临时使用 0.0.0.0/0，null 表示不开放 SSH"
  default     = null
  nullable    = true

  validation {
    condition     = var.ssh_source_cidr == null ? true : can(cidrnetmask(var.ssh_source_cidr))
    error_message = "SSH 来源必须是有效 IPv4 CIDR（临时可用 0.0.0.0/0），或使用 null 关闭。"
  }
}

variable "image_id" {
  type        = string
  description = "目标地域可用的 Ubuntu 24.04 x86_64 镜像 ID（必填）"

  validation {
    condition     = can(regex("^image-[a-z0-9]+$", var.image_id))
    error_message = "填写目标地域有效的 image- 开头镜像 ID。"
  }
}

variable "instance_type" {
  type        = string
  description = "RAG Web ECS 实例规格"
  default     = "ecs.g3i.large"
}

variable "ecs_login_mode" {
  type        = string
  description = "ECS 登录凭据模式：key_pair 或 password"
  default     = "key_pair"

  validation {
    condition     = contains(["key_pair", "password"], var.ecs_login_mode)
    error_message = "ecs_login_mode 必须是 key_pair 或 password。"
  }
}

variable "key_pair_name" {
  type        = string
  description = "key_pair 模式绑定的已有 ECS 密钥对名称；password 模式须为 null"
  default     = null
  nullable    = true

  validation {
    condition     = var.key_pair_name == null ? true : length(trimspace(var.key_pair_name)) > 0
    error_message = "key_pair_name 必须为 null 或非空的已有 ECS 密钥对名称。"
  }
}

# 示例默认值；密码模式部署前通过变量文件、环境变量或平台敏感参数提供实际密码。
variable "ecs_password" {
  type        = string
  description = "password 模式的 ECS 初始管理员密码；该值会保存到 Terraform State"
  default     = "ReplaceWithStrongPassword123"
  nullable    = true
  sensitive   = true

  validation {
    condition = var.ecs_password == null ? true : (
      length(var.ecs_password) >= 8 &&
      length(var.ecs_password) <= 30 &&
      (
        (length(regexall("[A-Z]", var.ecs_password)) > 0 ? 1 : 0) +
        (length(regexall("[a-z]", var.ecs_password)) > 0 ? 1 : 0) +
        (length(regexall("[0-9]", var.ecs_password)) > 0 ? 1 : 0) +
        (length(regexall("[^A-Za-z0-9]", var.ecs_password)) > 0 ? 1 : 0)
      ) >= 3 &&
      can(regex("^[A-Za-z0-9`~!@#$%^&*()_+={}\\[\\]:;'<>,.?/|\\-]+$", var.ecs_password)) &&
      !startswith(var.ecs_password, "/") &&
      !startswith(var.ecs_password, "$6$")
    )
    error_message = "ecs_password 须为 8–30 位、至少包含三类字符、仅使用 ECS 支持字符，且不能以 / 或 $6$ 开头。"
  }
}

variable "public_bandwidth_mbps" {
  type        = number
  description = "ECS BGP 公网带宽上限"
  default     = 5
  validation {
    condition     = var.public_bandwidth_mbps >= 1 && var.public_bandwidth_mbps <= 200 && floor(var.public_bandwidth_mbps) == var.public_bandwidth_mbps
    error_message = "公网带宽须为 1–200 Mbps 的整数。"
  }
}

variable "system_disk_size_gb" {
  type        = number
  description = "ECS 系统盘大小，GiB"
  default     = 40
  validation {
    condition     = var.system_disk_size_gb >= 40 && var.system_disk_size_gb <= 2048 && floor(var.system_disk_size_gb) == var.system_disk_size_gb
    error_message = "系统盘容量须为 40–2048 GiB 的整数。"
  }
}

variable "postgres_version" {
  type        = string
  description = "本方案固定为 RDS PostgreSQL 14"
  default     = "PostgreSQL_14"

  validation {
    condition     = var.postgres_version == "PostgreSQL_14"
    error_message = "本模板范围固定为 PostgreSQL_14。"
  }
}

variable "postgres_node_spec" {
  type        = string
  description = "RDS PostgreSQL 单节点规格"
  default     = "rds.postgres.1c2g"
}

variable "postgres_storage_gb" {
  type        = number
  description = "RDS PostgreSQL 存储空间，GiB"
  default     = 100
  validation {
    condition     = var.postgres_storage_gb >= 20 && var.postgres_storage_gb <= 3000 && var.postgres_storage_gb % 10 == 0
    error_message = "RDS 存储须为 20–3000 GiB，且为 10 GiB 的整数倍。"
  }
}

variable "postgres_database_name" {
  type        = string
  description = "RAG 数据库名称"
  default     = "ragdb"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.postgres_database_name))
    error_message = "数据库名称须以小写字母开头，仅包含小写字母、数字和下划线。"
  }
}

variable "postgres_admin_username" {
  type        = string
  description = "RDS PostgreSQL 初始化管理员账号；将由 Terraform 创建，供 ECS 首次初始化使用"
  default     = "ragbootstrap"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.postgres_admin_username))
    error_message = "postgres_admin_username 须以小写字母开头，仅包含小写字母、数字和下划线。"
  }
}

# 示例默认值；部署前通过变量文件、环境变量或平台敏感参数提供实际密码。
variable "postgres_admin_password" {
  type        = string
  description = "RDS PostgreSQL 初始化管理员账号密码；敏感值会保存到 Terraform State"
  default     = "ReplaceWithStrongPassword123"
  sensitive   = true

  validation {
    condition     = length(var.postgres_admin_password) >= 8 && length(var.postgres_admin_password) <= 32
    error_message = "postgres_admin_password 须为 8–32 位，并符合 RDS PostgreSQL 密码规则。"
  }
}

variable "ark_api_key" {
  type        = string
  description = "方舟控制台手工创建的 API Key；敏感值会保存到 Terraform State"
  sensitive   = true

  validation {
    condition     = length(trimspace(var.ark_api_key)) > 0
    error_message = "ark_api_key 不能为空。"
  }
}

variable "llm_foundation_model" {
  type        = string
  description = "方舟豆包生成模型名称"
  default     = "doubao-seed-2-0-lite"
}

variable "llm_model_version" {
  type        = string
  description = "方舟豆包生成模型版本；Plan 前按模型广场可用版本校验"
  default     = "260428"
}

variable "embedding_foundation_model" {
  type        = string
  description = "方舟多模态向量模型名称"
  default     = "doubao-embedding-vision"
}

variable "embedding_model_version" {
  type        = string
  description = "方舟多模态向量模型版本"
  default     = "251215"
}

variable "embedding_dimensions" {
  type        = number
  description = "pgvector 列维度，必须与 Embedding API 输出维度一致"
  default     = 1024

  validation {
    condition     = var.embedding_dimensions >= 1 && var.embedding_dimensions <= 2000 && floor(var.embedding_dimensions) == var.embedding_dimensions
    error_message = "向量维度须为 1–2000 的整数，并与所选模型实际支持的维度一致。"
  }
}

variable "moderation_strategy" {
  type        = string
  description = "方舟内容安全护栏策略"
  default     = "Default"
}

variable "common_tags" {
  type        = map(string)
  description = "统一资源标签"
  default = {
    Project     = "enterprise-ai-qa"
    Environment = "demo"
    ManagedBy   = "Terraform"
  }
}

variable "web_source_cidr" {
  type        = string
  description = "允许 HTTP 80 的 IPv4 来源；支持临时使用 0.0.0.0/0，长期使用建议指定访问网段或出口 /32"
  validation {
    condition     = can(cidrnetmask(var.web_source_cidr))
    error_message = "web_source_cidr 必须是有效 IPv4 CIDR，例如 203.0.113.10/32 或临时使用的 0.0.0.0/0。"
  }
}

variable "create_model_endpoints" {
  type        = bool
  description = "创建新 Ark Endpoint；false 时使用现有 Endpoint ID"
  default     = true
}

variable "model_endpoint_name_prefix" {
  type        = string
  description = "仅用于新建模型接入点的名称前缀；空值时使用 name_prefix，可设置独立前缀区分已有接入点"
  default     = ""
  validation {
    condition     = var.model_endpoint_name_prefix == "" || can(regex("^[a-z][a-z0-9-]{2,47}$", var.model_endpoint_name_prefix))
    error_message = "接入点前缀须为空或为 3–48 位小写字母、数字和连字符，并以字母开头。"
  }
}

variable "llm_endpoint_id" {
  type        = string
  description = "create_model_endpoints=false 时必填的现有生成 Endpoint ID"
  default     = ""
}

variable "embedding_endpoint_id" {
  type        = string
  description = "create_model_endpoints=false 时必填的现有向量 Endpoint ID"
  default     = ""
}

variable "ark_base_url" {
  type        = string
  description = "方舟推理 HTTPS 基础地址；空值时根据 region 生成，需确认对应地域支持模型"
  default     = ""
  validation {
    condition     = var.ark_base_url == "" || can(regex("^https://[a-z0-9.-]+/api/v3$", var.ark_base_url))
    error_message = "ARK 基础地址必须为 https://域名/api/v3，不可含凭据。"
  }
}

variable "chunk_size" {
  type        = number
  description = "文本切片字符数"
  default     = 800
  validation {
    condition     = var.chunk_size >= 128 && var.chunk_size <= 8000 && floor(var.chunk_size) == var.chunk_size
    error_message = "切片长度须为 128–8000 的整数。"
  }
}

variable "chunk_overlap" {
  type        = number
  description = "切片重叠字符数；必须小于 chunk_size"
  default     = 120
  validation {
    condition     = var.chunk_overlap >= 0 && floor(var.chunk_overlap) == var.chunk_overlap
    error_message = "重叠长度须为非负整数。"
  }
}

variable "default_top_k" {
  type        = number
  description = "默认召回切片数"
  default     = 5
  validation {
    condition     = contains([3, 5, 8, 10], var.default_top_k)
    error_message = "default_top_k 须为 3、5、8 或 10。"
  }
}

variable "max_upload_bytes" {
  type        = number
  description = "单文件上传字节上限，最高 20 MiB"
  default     = 10485760
  validation {
    condition     = var.max_upload_bytes >= 1 && var.max_upload_bytes <= 20971520 && floor(var.max_upload_bytes) == var.max_upload_bytes
    error_message = "上传上限须为 1–20971520 的整数。"
  }
}

variable "max_cosine_distance" {
  type        = number
  description = "召回余弦距离上限；需要用自己的知识集校准"
  default     = 0.65
  validation {
    condition     = var.max_cosine_distance >= 0 && var.max_cosine_distance <= 2
    error_message = "余弦距离上限须在 0–2 之间。"
  }
}
