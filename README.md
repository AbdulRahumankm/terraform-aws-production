# 🏗️ Production-Grade AWS Infrastructure with Terraform

Enterprise-level AWS infrastructure as code using Terraform. Modular, secure, and production-ready.

## 📦 What's Included

| Module | Description |
|--------|-------------|
| **VPC** | Multi-AZ VPC with public, private, and database subnets, NAT Gateways, VPC endpoints |
| **EKS** | Managed Kubernetes cluster with node groups, OIDC, add-ons |
| **RDS** | PostgreSQL with Multi-AZ, encryption, automated backups |
| **S3** | Buckets with versioning, encryption, lifecycle policies |
| **ALB** | Application Load Balancer with target groups, SSL/TLS |
| **IAM** | Least-privilege roles for EKS and applications |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         VPC (10.0.0.0/16)                       │
├─────────────────────────────────────────────────────────────────┤
│  Public Subnets (ALB)    │  Private Subnets (EKS Nodes)       │
│  - az-1a, az-1b, az-1c   │  - az-1a, az-1b, az-1c             │
├─────────────────────────────────────────────────────────────────┤
│  Database Subnets (RDS)                                         │
│  - az-1a, az-1b, az-1c (Multi-AZ)                              │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
terraform-aws-production/
├── environments/
│   └── prod/
│       ├── main.tf          # Composition: all modules
│       ├── variables.tf    # Input variables
│       ├── outputs.tf      # Output values
│       └── backend.hcl     # Remote state config
├── modules/
│   ├── vpc/               # VPC, subnets, NAT, endpoints
│   ├── eks/               # EKS cluster, node groups
│   ├── rds/              # PostgreSQL database
│   ├── s3/               # S3 buckets
│   ├── alb/               # Load balancer
│   └── iam/               # IAM roles
└── README.md
```

## 🚀 Quick Start

### 1. Configure AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"
```

### 2. Create S3 Backend Bucket (for state)

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://your-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-locking \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 3. Update Backend Config

Edit `environments/prod/backend.hcl`:

```hcl
bucket = "your-terraform-state-bucket"
key    = "prod/aws-infra/terraform.tfstate"
region = "us-east-1"
dynamodb_table = "terraform-state-locking"
```

### 4. Initialize and Deploy

```bash
cd environments/prod

# Initialize Terraform
terraform init -backend-config=backend.hcl

# Plan changes
terraform plan -var-file=prod.tfvars

# Apply (type "yes" to confirm)
terraform apply -var-file=prod.tfvars
```

### 5. Configure kubectl

```bash
aws eks update-kubeconfig --name myapp-prod --region us-east-1
```

## ⚙️ Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS Region | `us-east-1` |
| `project_name` | Project name | `myapp` |
| `environment` | Environment | `prod` |
| `kubernetes_version` | K8s version | `1.29` |
| `db_instance_class` | RDS instance | `db.r6g.large` |
| `db_allocated_storage` | RDS storage (GB) | `100` |

Create a `prod.tfvars` file:

```hcl
aws_region         = "us-east-1"
project_name       = "myapp"
environment        = "prod"
kubernetes_version = "1.29"

db_password = "your-secure-password"  # Use SSM in production!
```

## 🔒 Security Features

- ✅ Encryption at rest (S3, RDS)
- ✅ Encryption in transit (TLS)
- ✅ VPC isolation
- ✅ Security groups (least privilege)
- ✅ IAM roles with minimal permissions
- ✅ S3 bucket policies (SSL enforcement)
- ✅ RDS deletion protection
- ✅ ALB deletion protection

## 📝 License

MIT License - Feel free to use this for your own projects!

## 👤 Author

AbdulRahuman - Cloud Automation & DevOps Engineer

---

**⚠️ Note:** This is infrastructure code. Always review `terraform plan` output before applying to production!
