# ============================================================================
# VPC Module
# ============================================================================

terraform {
  required_version = ">= 1.5.0"
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# ============================================================================
# Internet Gateway
# ============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

# ============================================================================
# Public Subnets
# ============================================================================

resource "aws_subnet" "public" {
  count = length(var.public_subnets_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name                                  = "${var.name}-public-${count.index + 1}"
      "kubernetes.io/role/elb"               = "1"
      "kubernetes.io/cluster/${var.name}" = "shared"
    }
  )
}

# ============================================================================
# Private Subnets
# ============================================================================

resource "aws_subnet" "private" {
  count = length(var.private_subnets_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnets_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name                                  = "${var.name}-private-${count.index + 1}"
      "kubernetes.io/role/internal-elb"     = "1"
      "kubernetes.io/cluster/${var.name}" = "shared"
    }
  )
}

# ============================================================================
# Database Subnets (for RDS)
# ============================================================================

resource "aws_subnet" "database" {
  count = length(var.database_subnets_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.database_subnets_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-database-${count.index + 1}"
    }
  )
}

# ============================================================================
# Database Subnet Group
# ============================================================================

resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-db-subnet-group"
    }
  )
}

# ============================================================================
# Elastic IPs for NAT Gateways
# ============================================================================

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? var.az_count : 0

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ============================================================================
# NAT Gateways
# ============================================================================

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? var.az_count : 0

  allocation_id = aws_eip_nat[count.index].id
  subnet_id      = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# To handle the count dependency
resource "aws_eip" "eip_nat" {
  count = var.enable_nat_gateway ? var.az_count : 0

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-eip-nat-${count.index + 1}"
    }
  )
}

# NAT Gateway with correct EIP reference
resource "aws_nat_gateway" "nat_gw" {
  count = var.enable_nat_gateway ? var.az_count : 0

  allocation_id = aws_eip.eip_nat[count.index].id
  subnet_id      = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-gw-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ============================================================================
# Route Tables
# ============================================================================

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-rt"
    }
  )
}

# Private Route Tables (one per AZ for NAT GW)
resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? var.az_count : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-rt-${count.index + 1}"
    }
  )
}

# ============================================================================
# Route Table Associations
# ============================================================================

# Public Subnet Associations
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Subnet Associations
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index % var.az_count].id
}

# ============================================================================
# VPC Endpoints (for private S3/DynamoDB access)
# ============================================================================

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id
  )

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-s3-endpoint"
    }
  )
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"

  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id
  )

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-dynamodb-endpoint"
    }
  )
}

# ============================================================================
# Security Groups
# ============================================================================

# Default Security Group
resource "aws_security_group" "default" {
  name        = "${var.name}-default-sg"
  description = "Default security group for ${var.name}"
  vpc_id      = aws_vpc.main.id

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
      Name = "${var.name}-default-sg"
    }
  )
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================================
# Outputs
# ============================================================================

output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "vpc_name" {
  value = var.name
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  value = aws_subnet.database[*].id
}

output "database_subnet_group_name" {
  value = aws_db_subnet_group.main.name
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.nat_gw[*].id
}

output "nat_gateway_ips" {
  value = aws_eip.eip_nat[*].allocation_id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_ids" {
  value = aws_route_table.private[*].id
}

output "default_security_group_id" {
  value = aws_security_group.default.id
}
