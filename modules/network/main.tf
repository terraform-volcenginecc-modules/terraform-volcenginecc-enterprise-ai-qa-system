###############################################################################
# network 模块
# 创建单 VPC、单子网和应用安全组。公网仅开放 SSH 22 与 HTTP 80；
# PostgreSQL 通过 RDS Allow List 限制为子网私网访问。
###############################################################################

resource "volcenginecc_vpc_vpc" "main" {
  vpc_name     = "${var.name_prefix}-vpc"
  cidr_block   = var.vpc_cidr
  project_name = var.project_name
  tags         = var.tags_list

  lifecycle {
    precondition {
      condition = try(
        cidrnetmask(var.vpc_cidr) != "" &&
        cidrnetmask(var.subnet_cidr) != "" &&
        tonumber(split("/", var.subnet_cidr)[1]) >= tonumber(split("/", var.vpc_cidr)[1]) &&
        cidrhost("${cidrhost(var.subnet_cidr, 0)}/${split("/", var.vpc_cidr)[1]}", 0) == cidrhost(var.vpc_cidr, 0),
        false
      )
      error_message = "VPC 和子网必须为 IPv4 CIDR，且子网必须完整位于 VPC 内。"
    }
  }
}

resource "volcenginecc_vpc_subnet" "main" {
  vpc_id      = volcenginecc_vpc_vpc.main.id
  zone_id     = var.zone_id
  subnet_name = "${var.name_prefix}-subnet"
  cidr_block  = var.subnet_cidr
  tags        = var.tags_list
}

resource "volcenginecc_vpc_security_group" "app" {
  vpc_id              = volcenginecc_vpc_vpc.main.id
  security_group_name = "${var.name_prefix}-app-sg"
  description         = "Security group for the RAG web application"
  project_name        = var.project_name

  # Avoid overlapping subnet and security-group operations in the same VPC.
  depends_on = [volcenginecc_vpc_subnet.main]

  ingress_permissions = concat(var.ssh_source_cidr == null ? [] : [
    {
      description     = "Allow SSH from the configured administration CIDR"
      direction       = "ingress"
      policy          = "accept"
      port_start      = 22
      port_end        = 22
      protocol        = "tcp"
      priority        = 1
      cidr_ip         = var.ssh_source_cidr
      prefix_list_id  = ""
      source_group_id = ""
    }
    ], [
    {
      description     = "Allow HTTP to the RAG web interface"
      direction       = "ingress"
      policy          = "accept"
      port_start      = 80
      port_end        = 80
      protocol        = "tcp"
      priority        = 2
      cidr_ip         = var.web_source_cidr
      prefix_list_id  = ""
      source_group_id = ""
    }
  ])

  tags = var.tags_list
}
