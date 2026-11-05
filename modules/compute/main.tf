###############################################################################
# compute 模块
# 创建 ECS，由 cloud-init 从 TOS 下载无秘密源码并异步安装应用。
###############################################################################

locals {
  bootstrap_script = templatefile("${path.module}/templates/bootstrap-host.sh.tftpl", {
    source_url_base64 = base64encode(var.source_url)
    payload_sha256    = var.source_sha256
    config_base64     = base64encode(jsonencode(var.runtime_config))
    bootstrap_id      = sha256("${var.source_sha256}:${jsonencode(var.runtime_config)}")
  })
}

resource "volcenginecc_ecs_instance" "main" {
  instance_name             = "${var.name_prefix}-ecs"
  hostname                  = "rag-qa"
  description               = "RAG QA web application host managed by Terraform"
  instance_type             = var.instance_type
  zone_id                   = var.zone_id
  instance_charge_type      = "PostPaid"
  project_name              = var.project_name
  user_data                 = base64encode(local.bootstrap_script)
  install_run_command_agent = true
  password                  = var.login_mode == "password" ? var.password : null

  key_pair = var.login_mode == "key_pair" ? {
    key_pair_name = var.key_pair_name
  } : null

  image = {
    image_id                      = var.image_id
    security_enhancement_strategy = "Active"
  }

  primary_network_interface = {
    subnet_id          = var.subnet_id
    security_group_ids = [var.security_group_id]
  }

  system_volume = {
    size                 = var.system_disk_size_gb
    volume_type          = "ESSD_PL0"
    delete_with_instance = true
  }

  eip_address = {
    charge_type           = "PayByTraffic"
    bandwidth_mbps        = var.public_bandwidth_mbps
    isp                   = "BGP"
    release_with_instance = true
  }

  tags = concat(var.tags_list, [
    { key = "Role", value = "rag-web" }
  ])

  lifecycle {
    precondition {
      condition     = nonsensitive(length(base64encode(local.bootstrap_script))) <= 21844
      error_message = "cloud-init 脚本超过 ECS 16 KiB 限制。"
    }
    precondition {
      condition     = var.runtime_config.postgres_private_domain != ""
      error_message = "RDS 私网域名尚未就绪。"
    }
    precondition {
      condition = (
        (
          var.login_mode == "key_pair" &&
          var.key_pair_name != null &&
          nonsensitive(var.password == null)
        ) ||
        (
          var.login_mode == "password" &&
          var.key_pair_name == null &&
          nonsensitive(var.password != null)
        )
      )
      error_message = "ECS 登录凭据必须互斥：key_pair 模式需要 key_pair_name 且 password=null；password 模式需要 password 且 key_pair_name=null。"
    }
    ignore_changes = [
      user_data,
    ]
  }
}
