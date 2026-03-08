# ============================================================================
# IAM Module - Variables
# ============================================================================

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "prod"
}

variable "eks_cluster_name" {
  description = "EKS Cluster name"
  type        = string
  default     = ""
}

variable "eks_cluster_oidc_url" {
  description = "EKS Cluster OIDC URL"
  type        = string
  default     = ""
}

variable "oidc_thumbprint" {
  description = "OIDC Provider Thumbprint"
  type        = string
  default     = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
