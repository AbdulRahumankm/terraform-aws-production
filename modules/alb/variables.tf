# ============================================================================
# ALB Module - Variables
# ============================================================================

variable "name" {
  description = "ALB name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ALB"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Additional security group IDs"
  type        = list(string)
  default     = []
}

variable "internal" {
  description = "Create internal ALB"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Idle timeout in seconds"
  type        = number
  default     = 60
}

variable "drop_invalid_header_fields" {
  description = "Drop invalid header fields"
  type        = bool
  default     = true
}

variable "ssl_certificate_arn" {
  description = "SSL Certificate ARN (ACM)"
  type        = string
  default     = ""
}

variable "ssl_policy" {
  description = "SSL policy"
  type        = string
  default     = "ELBSecurityPolicy-2016-08"
}

variable "target_groups" {
  description = "Target groups configuration"
  type = list(object({
    name              = string
    port              = number
    protocol          = string
    target_type       = string
    health_check_path = string
  }))
  default = []
}

variable "default_target_group" {
  description = "Default target group name"
  type        = string
  default     = "web"
}

variable "listener_rules" {
  description = "Additional listener rules"
  type = list(object({
    name           = string
    priority       = number
    target_group   = string
    path_patterns = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
