###############################################################################
# 根模块：火山引擎企业智能问答系统
# Terraform 创建基础设施；cloud-init 使用用户提供的敏感运行时参数安装应用。
###############################################################################

module "network" {
  source = "./modules/network"

  name_prefix     = var.name_prefix
  project_name    = var.project_name
  zone_id         = var.zone_id
  vpc_cidr        = var.vpc_cidr
  subnet_cidr     = var.subnet_cidr
  ssh_source_cidr = var.ssh_source_cidr
  web_source_cidr = var.web_source_cidr
  tags_list       = local.tags_list
}

# ECS and RDS deletion return before their ENIs are fully detached. This
# barrier waits only during destroy, before Terraform removes VPC resources.
resource "time_sleep" "before_network_destroy" {
  destroy_duration = "60s"

  depends_on = [module.network]
}

module "database" {
  source = "./modules/database"

  name_prefix       = var.name_prefix
  project_name      = var.project_name
  zone_id           = var.zone_id
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.subnet_id
  subnet_cidr       = var.subnet_cidr
  db_engine_version = var.postgres_version
  node_spec         = var.postgres_node_spec
  storage_space_gb  = var.postgres_storage_gb
  database_name     = var.postgres_database_name
  admin_username    = var.postgres_admin_username
  admin_password    = var.postgres_admin_password
  tags_list         = local.tags_list
  depends_on        = [time_sleep.before_network_destroy]
}

module "inference" {
  source = "./modules/inference"

  create_endpoints           = var.create_model_endpoints
  llm_endpoint_id            = var.llm_endpoint_id
  embedding_endpoint_id      = var.embedding_endpoint_id
  name_prefix                = var.model_endpoint_name_prefix == "" ? var.name_prefix : var.model_endpoint_name_prefix
  project_name               = var.project_name
  llm_foundation_model       = var.llm_foundation_model
  llm_model_version          = var.llm_model_version
  embedding_foundation_model = var.embedding_foundation_model
  embedding_model_version    = var.embedding_model_version
  moderation_strategy        = var.moderation_strategy
  tags_list                  = local.tags_list
}

resource "terraform_data" "configuration" {
  input = var.name_prefix

  lifecycle {
    precondition {
      condition     = var.chunk_overlap < var.chunk_size
      error_message = "chunk_overlap 必须小于 chunk_size。"
    }
    precondition {
      condition     = startswith(var.zone_id, "${var.region}-")
      error_message = "zone_id 必须属于 region。"
    }
    precondition {
      condition = (
        (
          var.ecs_login_mode == "key_pair" &&
          var.key_pair_name != null &&
          nonsensitive(var.ecs_password == null)
        ) ||
        (
          var.ecs_login_mode == "password" &&
          var.key_pair_name == null &&
          nonsensitive(var.ecs_password != null)
        )
      )
      error_message = "ECS 登录凭据必须互斥：key_pair 模式需要 key_pair_name 且 ecs_password=null；password 模式需要 ecs_password 且 key_pair_name=null。"
    }
  }
}

module "delivery" {
  source = "./modules/delivery"

  name_prefix  = var.name_prefix
  project_name = var.project_name
  vpc_id       = module.network.vpc_id
  tags_list    = local.tags_list
}

module "compute" {
  source = "./modules/compute"

  name_prefix           = var.name_prefix
  project_name          = var.project_name
  zone_id               = var.zone_id
  subnet_id             = module.network.subnet_id
  security_group_id     = module.network.security_group_id
  image_id              = var.image_id
  instance_type         = var.instance_type
  login_mode            = var.ecs_login_mode
  key_pair_name         = var.key_pair_name
  password              = var.ecs_password
  public_bandwidth_mbps = var.public_bandwidth_mbps
  system_disk_size_gb   = var.system_disk_size_gb
  tags_list             = local.tags_list
  runtime_config        = local.runtime_config
  source_url            = module.delivery.source_url
  source_sha256         = module.delivery.source_sha256
  depends_on            = [terraform_data.configuration, module.database, time_sleep.before_network_destroy]
}
