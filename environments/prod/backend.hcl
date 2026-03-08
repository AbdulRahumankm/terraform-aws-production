# ============================================================================
# Terraform Remote State Configuration
# ============================================================================
# S3 Backend with DynamoDB state locking
# 
# Prerequisite: Create the S3 bucket and DynamoDB table manually or via:
#   terraform-aws-remote-state/setup.sh
# 
# Usage:
#   cd environments/prod
#   terraform init -backend-config=backend.hcl
# ============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Backend configuration (loaded from backend.hcl)
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "prod/aws-infra/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-locking"
#   }
# }
