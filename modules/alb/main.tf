# ============================================================================
# ALB Module
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
# ALB Security Group
# ============================================================================

resource "aws_security_group" "alb" {
  name        = "${var.name}-sg"
  description = "Security group for ALB ${var.name}"
  vpc_id      = var.vpc_id

  # Allow HTTP and HTTPS
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
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
      Name = "${var.name}-sg"
    }
  )
}

# ============================================================================
# Application Load Balancer
# ============================================================================

resource "aws_lb" "main" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = concat([aws_security_group.alb.id], var.security_group_ids)
  subnets           = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  drop_invalid_header_fields = var.drop_invalid_header_fields

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# ============================================================================
# Target Groups
# ============================================================================

resource "aws_lb_target_group" "main" {
  for_each = { for tg in var.target_groups : tg.name => tg }

  name     = each.value.name
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = var.vpc_id

  target_type = each.value.target_type

  # Health Check
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = each.value.health_check_path
    matcher             = "200"
  }

  # Stickiness
  stickiness {
    enabled         = true
    type           = "lb_cookie"
    cookie_duration = 86400
  }

  tags = merge(
    var.tags,
    {
      Name = each.value.name
    }
  )
}

# ============================================================================
# ALB Listener (HTTP - Redirect to HTTPS)
# ============================================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ============================================================================
# ALB Listener (HTTPS - Forward to Target Group)
# ============================================================================

resource "aws_lb_listener" "https" {
  count = var.ssl_certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main[var.default_target_group].arn
  }
}

# ============================================================================
# Listener Rules (for path-based routing)
# ============================================================================

resource "aws_lb_listener_rule" "main" {
  for_each = { for rule in var.listener_rules : rule.name => rule }

  listener_arn = aws_lb_listener.https[0].arn
  priority     = each.value.priority

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main[each.value.target_group].arn
  }

  condition {
    path_pattern {
      values = each.value.path_patterns
    }
  }
}

# ============================================================================
# Outputs
# ============================================================================

output "alb_id" {
  description = "ALB ID"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.main.zone_id
}

output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "target_group_arns" {
  description = "Target Group ARNs"
  value       = { for name, tg in aws_lb_target_group.main : name => tg.arn }
}

output "target_group_names" {
  description = "Target Group Names"
  value       = { for name, tg in aws_lb_target_group.main : name => tg.name }
}
