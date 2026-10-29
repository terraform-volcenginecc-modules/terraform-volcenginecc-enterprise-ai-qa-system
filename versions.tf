terraform {
  required_version = ">= 1.5.7"

  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "= 0.0.72"
    }
    # Destroy-only barriers allow asynchronous ECS/RDS detach operations to
    # settle before Terraform removes dependent network/database resources.
    time = {
      source  = "hashicorp/time"
      version = "= 0.14.2"
    }
  }
}
