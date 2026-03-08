# ============================================================================
# EKS Module - Variables
# ============================================================================

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS"
  type        = list(string)
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "prod"
}

variable "eks_cluster_role_arn" {
  description = "EKS Cluster IAM role ARN"
  type        = string
}

variable "eks_node_role_arn" {
  description = "EKS Node IAM role ARN"
  type        = string
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
  default = {}
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

variable "endpoint_private_access" {
  description = "Enable private endpoint access"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public endpoint access"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "Public access CIDRs"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
