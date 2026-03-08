# ============================================================================
# AWS Production Infrastructure - Outputs
# ============================================================================

# ============================================================================
# VPC Outputs
# ============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnet_ids
}

output "nat_gateway_ips" {
  description = "NAT Gateway Elastic IP addresses"
  value       = module.vpc.nat_gateway_ips
}

# ============================================================================
# S3 Outputs
# ============================================================================

output "s3_backend_bucket_arn" {
  description = "S3 backend bucket ARN"
  value       = module.s3_backend.bucket_arn
}

output "s3_backend_bucket_name" {
  description = "S3 backend bucket name"
  value       = module.s3_backend.bucket_name
}

output "s3_data_bucket_arn" {
  description = "S3 data bucket ARN"
  value       = module.s3_data.bucket_arn
}

output "s3_data_bucket_name" {
  description = "S3 data bucket name"
  value       = module.s3_data.bucket_name
}

# ============================================================================
# IAM Outputs
# ============================================================================

output "eks_cluster_role_arn" {
  description = "EKS Cluster IAM role ARN"
  value       = module.iam.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  description = "EKS Node IAM role ARN"
  value       = module.iam.eks_node_role_arn
}

output "eks_worker_instance_profile" {
  description = "EKS Worker instance profile name"
  value       = module.iam.eks_worker_instance_profile
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

# ============================================================================
# EKS Outputs
# ============================================================================

output "eks_cluster_id" {
  description = "EKS Cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority" {
  description = "EKS Cluster CA certificate"
  value       = module.eks.cluster_certificate_authority
}

output "eks_cluster_security_group_id" {
  description = "EKS Cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_group_ids" {
  description = "EKS Node Group IDs"
  value       = module.eks.node_group_ids
}

output "eks_kubeconfig" {
  description = "Kubeconfig for EKS cluster"
  value       = module.eks.kubeconfig
  sensitive   = true
}

# ============================================================================
# RDS Outputs
# ============================================================================

output "rds_instance_id" {
  description = "RDS Instance ID"
  value       = module.rds.instance_id
}

output "rds_instance_endpoint" {
  description = "RDS Instance endpoint"
  value       = module.rds.instance_endpoint
}

output "rds_instance_port" {
  description = "RDS Instance port"
  value       = module.rds.instance_port
}

output "rds_instance_arn" {
  description = "RDS Instance ARN"
  value       = module.rds.instance_arn
}

output "rds_database_name" {
  description = "RDS Database name"
  value       = module.rds.database_name
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = module.rds.security_group_id
}

# ============================================================================
# ALB Outputs
# ============================================================================

output "alb_id" {
  description = "ALB ID"
  value       = module.alb.alb_id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.alb.alb_arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = module.alb.alb_zone_id
}

output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = module.alb.security_group_id
}

output "alb_target_group_arns" {
  description = "ALB Target Group ARNs"
  value       = module.alb.target_group_arns
}
