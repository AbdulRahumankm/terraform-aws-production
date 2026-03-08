# ============================================================================
# RDS Module
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
# RDS Security Group
# ============================================================================

resource "aws_security_group" "rds" {
  name        = "${var.identifier}-sg"
  description = "Security group for RDS ${var.identifier}"
  vpc_id      = var.vpc_id

  # Allow PostgreSQL from private subnets
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/8"]  # Adjust as needed
    description     = "PostgreSQL from VPC"
  }

  # Allow from ALB security group
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.security_group_ids
    description     = "PostgreSQL from ALB"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-sg"
    }
  )
}

# ============================================================================
# RDS Instance
# ============================================================================

resource "aws_db_instance" "main" {
  identifier     = var.identifier
  engine        = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = var.storage_type
  storage_encrypted    = var.storage_encrypted

  # Multi-AZ
  multi_az = var.multi_az

  # Database
  db_name  = var.db_name
  username = var.username
  password = var.password

  # Port
  port = var.port

  # Network
  db_subnet_group_name   = var.subnet_ids != null ? var.db_subnet_group_name : null
  vpc_security_group_ids = concat([aws_security_group.rds.id], var.security_group_ids)

  # Backup
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  skip_final_snapshot    = var.skip_final_snapshot
  final_snapshot_identifier = var.multi_az ? "${var.identifier}-final-${formatdate("YYYYMMDD", timestamp())}" : null

  # Performance Insights
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  performance_insights_enabled  = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_kms_key_id

  # Deletion protection
  deletion_protection = var.deletion_protection

  # Tags
  tags = merge(
    var.tags,
    {
      Name = var.identifier
    }
  )
}

# ============================================================================
# Outputs
# ============================================================================

output "instance_id" {
  description = "RDS Instance ID"
  value       = aws_db_instance.main.id
}

output "instance_endpoint" {
  description = "RDS Instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "instance_port" {
  description = "RDS Instance port"
  value       = aws_db_instance.main.port
}

output "instance_arn" {
  description = "RDS Instance ARN"
  value       = aws_db_instance.main.arn
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}
