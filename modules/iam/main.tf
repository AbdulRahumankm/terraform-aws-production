# ============================================================================
# IAM Module
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
# EKS Cluster Role
# ============================================================================

resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_vpc_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_cluster.name
}

# ============================================================================
# EKS Node Role
# ============================================================================

resource "aws_iam_role" "eks_node" {
  name = "${var.project_name}-${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

# ============================================================================
# EKS Node Instance Profile
# ============================================================================

resource "aws_iam_instance_profile" "eks_node" {
  name = "${var.project_name}-${var.environment}-eks-node-profile"
  role = aws_iam_role.eks_node.name

  tags = var.tags
}

# ============================================================================
# Application Role (for pods)
# ============================================================================

resource "aws_iam_role" "app" {
  name = "${var.project_name}-${var.environment}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    },
    {
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Condition = {
        StringEquals = {
          "${aws_iam_openid_connect_provider.main.arn}:sub" = "system:serviceaccount:default:default"
        }
      }
    }]
  })

  tags = var.tags
}

# ============================================================================
# OIDC Provider for EKS
# ============================================================================

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.oidc_thumbprint]
  url             = var.eks_cluster_oidc_url

  tags = var.tags
}

# ============================================================================
# Outputs
# ============================================================================

output "eks_cluster_role_arn" {
  description = "EKS Cluster Role ARN"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "EKS Node Role ARN"
  value       = aws_iam_role.eks_node.arn
}

output "eks_worker_instance_profile" {
  description = "EKS Worker Instance Profile Name"
  value       = aws_iam_instance_profile.eks_node.name
}

output "app_role_arn" {
  description = "Application Role ARN"
  value       = aws_iam_role.app.arn
}

output "oidc_provider_arn" {
  description = "OIDC Provider ARN"
  value       = aws_iam_openid_connect_provider.main.arn
}
