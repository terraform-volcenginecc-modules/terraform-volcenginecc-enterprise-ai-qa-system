###############################################################################
# database 模块
# 创建双节点高可用 RDS PostgreSQL、RAG 数据库与子网白名单。
# 初始化账号由 Terraform 创建；密码作为敏感输入保存在 Terraform State。
###############################################################################

resource "volcenginecc_rdspostgresql_instance" "main" {
  instance_name     = "${var.name_prefix}-postgres"
  db_engine_version = var.db_engine_version
  storage_type      = "LocalSSD"
  storage_space     = var.storage_space_gb
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  project_name      = var.project_name
  allow_list_ids    = [volcenginecc_rdspostgresql_allow_list.app_subnet.allow_list_id]

  charge_detail = {
    charge_type = "PostPaid"
  }

  node_info = [
    {
      zone_id   = var.zone_id
      node_spec = var.node_spec
      node_type = "Primary"
    },
    {
      zone_id   = var.zone_id
      node_spec = var.node_spec
      node_type = "Secondary"
    }
  ]

  tags = var.tags_list

  depends_on = [time_sleep.before_allow_list_destroy]
}

resource "volcenginecc_rdspostgresql_allow_list" "app_subnet" {
  allow_list_name     = "${var.name_prefix}-app-subnet"
  allow_list_desc     = "Allow PostgreSQL access only from the application subnet"
  allow_list_type     = "IPv4"
  allow_list_category = "Ordinary"
  allow_list          = [var.subnet_cidr]
  modify_mode         = "Cover"

}

# RDS deletion is asynchronous. Wait only during destroy before removing the
# allow list, otherwise the service can still report the deleted instance bound.
resource "time_sleep" "before_allow_list_destroy" {
  destroy_duration = "300s"

  depends_on = [volcenginecc_rdspostgresql_allow_list.app_subnet]
}

resource "volcenginecc_rdspostgresql_database" "rag" {
  instance_id        = volcenginecc_rdspostgresql_instance.main.instance_id
  db_name            = var.database_name
  character_set_name = "utf8"
  collate            = "C.UTF-8"
  c_type             = "C.UTF-8"
}

resource "volcenginecc_rdspostgresql_db_account" "bootstrap" {
  instance_id        = volcenginecc_rdspostgresql_instance.main.instance_id
  account_name       = var.admin_username
  account_password   = var.admin_password
  account_type       = "Super"
  account_privileges = "Login,Inherit,CreateDB,CreateRole"

  depends_on = [volcenginecc_rdspostgresql_database.rag]
}

locals {
  private_addresses = flatten([
    for endpoint in volcenginecc_rdspostgresql_instance.main.endpoints : [
      for address in endpoint.address : address
      if address.network_type == "Private"
    ]
  ])
}
