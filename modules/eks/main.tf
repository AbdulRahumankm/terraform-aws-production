# ============================================================================
# EKS Module
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ============================================================================
# EKS Cluster
# ============================================================================

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.eks_cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  enabled_cluster_log_types = var.cluster_log_types

  # Encryption configuration
  encryption_config {
    resources = ["secrets"]
    provider {
      name = "aws"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# ============================================================================
# EKS Node Group - Managed Node Groups
# ============================================================================

resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn  = var.eks_node_role_arn
  subnet_ids    = var.subnet_ids
  instance_types = each.value.instance_types

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  capacity_type = each.value.capacity_type

  # Labels
  labels = {
    "environment" = var.environment
    "node-group" = each.key
  }

  # Taints (if needed)
  # taint {
  #   key    = "dedicated"
  #   value  = "gpu"
  #   effect = "NO_SCHEDULE"
  # }

  # Disk size
  root_volume_size = each.value.disk_size

  # Update configuration
  update_config {
    max_unavailable = 1
  }

  # Tags
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-${each.key}"
    }
  )
}

# ============================================================================
# EKS Add-ons
# ============================================================================

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
  addon_version = "v1.15.4-eksbuild.1"

  tags = var.tags
}

resource "aws_eks_addon" "core_dns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
  addon_version = "v1.11.0-eksbuild.2"

  tags = var.tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
  addon_version = "v1.29.0-eksbuild.2"

  tags = var.tags
}

# ============================================================================
# IAM Role for EKS Cluster
# ============================================================================

# Note: The cluster and node IAM roles are now managed by the IAM module
# These are here for reference only

# ============================================================================
# Outputs
# ============================================================================

output "cluster_id" {
  value = aws_eks_cluster.main.id
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.main.vpc_config[0].security_group_ids[0]
}

output "node_group_ids" {
  value = [for ng in aws_eks_node_group.main : ng.id]
}

output "cluster_oidc_issuer" {
  value = aws_eks_cluster.main.oidc[0].issuer
}

output "cluster_arn" {
  value = aws_eks_cluster.main.arn
}

# Kubeconfig generation (for kubectl)
output "kubeconfig" {
  value = <<-EOT
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${aws_eks_cluster.main.certificate_authority[0].data}
    server: ${aws_eks_cluster.main.endpoint}
  name: ${var.cluster_name}
contexts:
- context:
    cluster: ${var.cluster_name}
    user: ${var.cluster_name}
  name: ${var.cluster_name}
current-context: ${var.cluster_name}
kind: Config
users:
- name: ${var.cluster_name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - eks
        - get-token
        - --cluster-name
        - ${var.cluster_name}
      env:
        - name: AWS_REGION
          value: ${var.aws_region}
EOT
}
