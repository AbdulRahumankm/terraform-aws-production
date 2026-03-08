# ============================================================================
# AWS Production Infrastructure - Main Configuration
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

# ============================================================================
# Providers
# ============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }

  skip_credentials_validation = var.skip_credentials_validation
  skip_metadata_api_check      = var.skip_metadata_api_check
  s3_use_path_style           = var.s3_use_path_style
}

provider "aws" {
  alias  = "secondary_region"
  region = var.secondary_region

  default_tags {
    tags = var.common_tags
  }

  skip_credentials_validation = var.skip_credentials_validation
  skip_metadata_api_check      = var.skip_metadata_api_check
  s3_use_path_style           = var.s3_use_path_style
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# ============================================================================
# Remote State (Optional - uncomment if using remote state)
# ============================================================================

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "prod/aws-infra/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-locking"
#   }
# }

# ============================================================================
# VPC Module
# ============================================================================

module "vpc" {
  source = "../../modules/vpc"

  name                  = "${var.project_name}-${var.environment}-vpc"
  cidr_block           = var.vpc_cidr
  az_count             = var.availability_zones_count
  enable_nat_gateway   = var.enable_nat_gateway
  enable_vpn_gateway   = var.enable_vpn_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnets_cidrs  = var.public_subnets_cidrs
  private_subnets_cidrs = var.private_subnets_cidrs
  database_subnets_cidrs = var.database_subnets_cidrs

  tags = var.common_tags
}

# ============================================================================
# S3 Backend Storage Module
# ============================================================================

module "s3_backend" {
  source = "../../modules/s3"

  bucket_name     = "${var.project_name}-${var.environment}-backend"
  environment    = var.environment
  enable_versioning = true
  enable_encryption = true
  enable_lifecycle_rules = true

  tags = var.common_tags
}

# ============================================================================
# S3 Data Bucket Module
# ============================================================================

module "s3_data" {
  source = "../../modules/s3"

  bucket_name     = "${var.project_name}-${var.environment}-data"
  environment    = var.environment
  enable_versioning = var.s3_enable_versioning
  enable_encryption = true
  enable_lifecycle_rules = true

  tags = var.common_tags
}

# ============================================================================
# IAM Module
# ============================================================================

module "iam" {
  source = "../../modules/iam"

  project_name  = var.project_name
  environment  = var.environment
  eks_cluster_name = module.eks.cluster_name

  tags = var.common_tags
}

# ============================================================================
# EKS Module
# ============================================================================

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = var.kubernetes_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids

  # EKS Managed Node Groups
  node_groups = var.node_groups

  # Cluster IAM Role
  eks_cluster_role_arn = module.iam.eks_cluster_role_arn
  eks_node_role_arn    = module.iam.eks_node_role_arn

  # Security
  enable_cluster_logging = var.enable_cluster_logging
  cluster_log_types      = var.cluster_log_types

  tags = var.common_tags
}

# ============================================================================
# RDS Module
# ============================================================================

module "rds" {
  source = "../../modules/rds"

  identifier           = "${var.project_name}-${var.environment}-db"
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  storage_encrypted    = true
  multi_az             = var.db_multi_az

  # Network
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.database_subnet_ids
  security_group_ids = [module.rds.security_group_id]

  # Database
  db_name     = var.db_name
  username    = var.db_username
  password    = var.db_password # Use SSM parameter in production!

  # Backup
  backup_retention_period = var.db_backup_retention
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  # Tags
  tags = var.common_tags
}

# ============================================================================
# Application Load Balancer Module
# ============================================================================

module "alb" {
  source = "../../modules/alb"

  name               = "${var.project_name}-${var.environment}-alb"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.alb.security_group_id]

  # HTTPS (production should use ACM certificate)
  enable_deletion_protection = var.alb_enable_deletion_protection
  idle_timeout               = var.alb_idle_timeout

  # Target Groups
  target_groups = var.alb_target_groups

  tags = var.common_tags
}
