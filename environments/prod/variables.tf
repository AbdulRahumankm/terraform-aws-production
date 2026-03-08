# ============================================================================
# AWS Production Infrastructure - Variables
# ============================================================================

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for DR"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# ============================================================================
# VPC Configuration
# ============================================================================

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of Availability Zones to use"
  type        = number
  default     = 3
}

variable "public_subnets_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "database_subnets_cidrs" {
  description = "Database subnet CIDRs"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway for Site-to-Site VPN"
  type        = bool
  default     = false
}

# ============================================================================
# EKS Configuration
# ============================================================================

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "node_groups" {
  description = "EKS managed node groups configuration"
  type = map(object({
    instance_types = list(string)
    min_size        = number
    max_size        = number
    desired_size    = number
    capacity_type   = string
    disk_size       = number
  }))
  default = {
    general = {
      instance_types = ["m5.large"]
      min_size        = 2
      max_size        = 10
      desired_size    = 3
      capacity_type   = "ON_DEMAND"
      disk_size       = 50
    }
    memory = {
      instance_types = ["r5.xlarge"]
      min_size        = 1
      max_size        = 5
      desired_size    = 2
      capacity_type   = "ON_DEMAND"
      disk_size       = 100
    }
  }
}

variable "enable_cluster_logging" {
  description = "Enable EKS cluster logging"
  type        = bool
  default     = true
}

variable "cluster_log_types" {
  description = "EKS cluster log types"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# ============================================================================
# RDS Configuration
# ============================================================================

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.4"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Database master password (use SSM in production!)"
  type        = string
  default     = "" # Set via environment variable or SSM
  sensitive   = true
}

variable "db_backup_retention" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

# ============================================================================
# S3 Configuration
# ============================================================================

variable "s3_enable_versioning" {
  description = "Enable S3 versioning"
  type        = bool
  default     = true
}

# ============================================================================
# ALB Configuration
# ============================================================================

variable "alb_enable_deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = true
}

variable "alb_idle_timeout" {
  description = "ALB idle timeout in seconds"
  type        = number
  default     = 60
}

variable "alb_target_groups" {
  description = "ALB target groups configuration"
  type = list(object({
    name     = string
    port     = number
    protocol = string
    target_type = string
    health_check_path = string
  }))
  default = [
    {
      name     = "web"
      port     = 80
      protocol = "HTTP"
      target_type = "instance"
      health_check_path = "/health"
    },
    {
      name     = "web-https"
      port     = 443
      protocol = "HTTPS"
      target_type = "instance"
      health_check_path = "/health"
    }
  ]
}

# ============================================================================
# Tags
# ============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "myapp"
    Environment = "prod"
    ManagedBy   = "Terraform"
    Owner       = "platform-team"
  }
}

# ============================================================================
# Provider Configuration (for local testing)
# ============================================================================

variable "skip_credentials_validation" {
  description = "Skip credentials validation (for local testing)"
  type        = bool
  default     = false
}

variable "skip_metadata_api_check" {
  description = "Skip metadata API check"
  type        = bool
  default     = false
}

variable "s3_use_path_style" {
  description = "Use path-style S3 access"
  type        = bool
  default     = false
}
