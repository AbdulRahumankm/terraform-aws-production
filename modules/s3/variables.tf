# ============================================================================
# S3 Module - Variables
# ============================================================================

variable "bucket_name" {
  description = "S3 Bucket name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "prod"
}

variable "enable_versioning" {
  description = "Enable bucket versioning"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable server-side encryption"
  type        = bool
  default     = true
}

variable "enable_lifecycle_rules" {
  description = "Enable lifecycle rules"
  type        = bool
  default     = true
}

variable "lifecycle_noncurrent_days" {
  description = "Days before transitioning to Glacier"
  type        = number
  default     = 30
}

variable "lifecycle_expiration_days" {
  description = "Days before expiring non-current versions"
  type        = number
  default     = 90
}

variable "enforce_ssl" {
  description = "Enforce SSL for all connections"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
