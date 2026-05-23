locals {
  # 1. Tags configuration
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
