# ============================================================================
# S3 Module
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
# S3 Bucket
# ============================================================================

resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}

# ============================================================================
# S3 Bucket Versioning
# ============================================================================

resource "aws_s3_bucket_versioning" "main" {
  count = var.enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ============================================================================
# S3 Bucket Encryption
# ============================================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.enable_encryption ? 1 : 0

  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ============================================================================
# S3 Bucket Lifecycle Rules
# ============================================================================

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = var.enable_lifecycle_rules ? 1 : 0

  bucket = aws_s3_bucket.main.id

  rule {
    id     = "archive-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = var.lifecycle_noncurrent_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_expiration_days
    }
  }
}

# ============================================================================
# S3 Bucket Public Access Block
# ============================================================================

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================================
# S3 Bucket Policy (if needed for VPC endpoints)
# ============================================================================

resource "aws_s3_bucket_policy" "main" {
  count = var.enforce_ssl ? 1 : 0

  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ForceSSL"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "${aws_s3_bucket.main.arn}/*",
          "${aws_s3_bucket.main.arn}"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ============================================================================
# S3 Bucket Ownership Controls
# ============================================================================

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# ============================================================================
# Outputs
# ============================================================================

output "bucket_name" {
  description = "S3 Bucket name"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "S3 Bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "S3 Bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}
