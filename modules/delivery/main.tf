###############################################################################
# delivery 模块
# 将不含秘密的应用源码压缩为文本对象，供 ECS cloud-init 下载。
###############################################################################

locals {
  source_root = "${path.module}/../.."
  payload = jsonencode(merge(
    { for name in fileset("${local.source_root}/app", "**") :
      "app/${name}" => filebase64("${local.source_root}/app/${name}")
      if can(regex("\\.(py|txt|html|css|js)$", name)) && !can(regex("(^|/)(__pycache__|\\.venv)(/|$)", name))
    },
    { for name in ["ecs-runtime.py", "auto-install.sh"] :
      "scripts/${name}" => filebase64("${path.module}/templates/${name}")
    }
  ))
  payload_sha256 = sha256(local.payload)
  payload_base64 = base64gzip(local.payload)
  bucket_name    = "${var.name_prefix}-${substr(sha256(var.vpc_id), 0, 12)}"
}

resource "volcenginecc_tos_bucket" "source" {
  name          = local.bucket_name
  bucket_type   = "fns"
  storage_class = "STANDARD"
  project_name  = var.project_name
  tags          = var.tags_list
}

# The object contains public application source and non-secret installer code.
# Object-level public read lets cloud-init download without embedding credentials.
resource "volcenginecc_tos_object" "source" {
  bucket                 = volcenginecc_tos_bucket.source.name
  key                    = "enterprise-qa/${local.payload_sha256}.txt"
  content                = local.payload_base64
  content_type           = "text/plain; charset=utf-8"
  public_acl             = "public-read"
  storage_class          = "STANDARD"
  server_side_encryption = "AES256"
  tags                   = var.tags_list

  lifecycle {
    precondition {
      condition     = length(local.payload_base64) <= 10 * 1024 * 1024
      error_message = "应用源码对象超过 TOS 文本对象 10 MiB 限制。"
    }
  }
}
