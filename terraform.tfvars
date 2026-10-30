region          = "cn-beijing"
zone_id         = "cn-beijing-a"
project_name    = "default"
name_prefix     = "enterprise-ai-qa"
vpc_cidr        = "10.40.0.0/16"
subnet_cidr     = "10.40.1.0/24"
web_source_cidr = "0.0.0.0/0" # 文档示例网段，必须改为实际访问出口
ssh_source_cidr = "0.0.0.0/0" # 临时公网 SSH，验证后收敛为实际来源或设为 null
ecs_login_mode  = "key_pair"
key_pair_name   = "wordpress" # 部署前填写目标地域中已有的 ECS 密钥对名称
ecs_password    = null
# 密码模式改为 ecs_login_mode="password"、key_pair_name=null，并填写 ecs_password。
# 若用 TF_VAR_ecs_password 输入，先注释或删除上面的 ecs_password=null；InfraManager 可使用敏感参数输入。
image_id              = "image-ydf193g9cqb6uoeqqqj8"
instance_type         = "ecs.g3i.large"
public_bandwidth_mbps = 5
system_disk_size_gb   = 40

postgres_version       = "PostgreSQL_14"
postgres_node_spec     = "rds.postgres.2c4g"
postgres_storage_gb    = 100
postgres_database_name = "ragdb"

# 以下变量已在 variables.tf 中标记 sensitive；示例值在部署前替换。
# 文件输入：填写实际值；环境变量输入：先注释或删除对应赋值，再设置 TF_VAR_*。
# InfraManager 可使用敏感参数输入；不要将真实凭据提交到代码库。
postgres_admin_password = "ReplaceWithStrongPassword123"
ark_api_key             = "ark-xxxxxxxxxx"
# 默认管理员账号为 ragbootstrap；需要变更时可取消注释：
postgres_admin_username = "ragbootstrap"

# 模型需在所选地域开通；版本和库存应在部署前确认。
create_model_endpoints     = true
model_endpoint_name_prefix = "enterprise-ai-qa-20261026"
llm_foundation_model       = "doubao-seed-2-0-lite"
llm_model_version          = "260428"
embedding_foundation_model = "doubao-embedding-vision"
embedding_model_version    = "251215"
embedding_dimensions       = 1024
# 复用 Endpoint 时改为 false，并填入两个 ep-...，这些 ID 不是 API Key：
# llm_endpoint_id       = "ep-..."
# embedding_endpoint_id = "ep-..."
# ark_base_url          = "https://ark.cn-beijing.volces.com/api/v3"

chunk_size          = 800
chunk_overlap       = 120
default_top_k       = 5
max_upload_bytes    = 10485760
max_cosine_distance = 0.65
