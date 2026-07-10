terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  
  # Using local backend - state will be stored in terraform.tfstate in this directory
  # This is automatically gitignored for security
}

provider "aws" {
  region = var.aws_region
}

# Data source for current caller identity
data "aws_caller_identity" "current" {}

# ========================================
# Aurora Serverless v2 PostgreSQL Cluster
# ========================================

# Random password for database
# Reference the manually-created secret (not managed by Terraform)
data "aws_secretsmanager_secret" "db_credentials" {
  name = "alex-aurora-credentials"
}

# Reference the manually-created Aurora cluster (not managed by Terraform)
data "aws_rds_cluster" "aurora" {
  cluster_identifier = "alex-aurora-cluster"
}
# IAM role for Lambda to access Aurora Data API
resource "aws_iam_role" "lambda_aurora_role" {
  name = "alex-lambda-aurora-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Project = "alex"
    Part    = "5"
  }
}

# IAM policy for Data API access
resource "aws_iam_role_policy" "lambda_aurora_policy" {
  name = "alex-lambda-aurora-policy"
  role = aws_iam_role.lambda_aurora_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction"
        ]
        #Resource = aws_rds_cluster.aurora.arn
        Resource = data.aws_rds_cluster.aurora.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        #Resource = aws_secretsmanager_secret.db_credentials.arn
        Resource = data.aws_secretsmanager_secret.db_credentials.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# Attach basic Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_aurora_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
