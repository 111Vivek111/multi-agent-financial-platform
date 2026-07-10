output "aurora_cluster_arn" {
  description = "ARN of the Aurora cluster"
  value       = data.aws_rds_cluster.aurora.arn
}

output "aurora_cluster_endpoint" {
  description = "Writer endpoint for the Aurora cluster"
  value       = data.aws_rds_cluster.aurora.endpoint
}

output "aurora_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = data.aws_secretsmanager_secret.db_credentials.arn
}

output "database_name" {
  description = "Name of the database"
  value       = "alex"
}

output "lambda_role_arn" {
  description = "ARN of the IAM role for Lambda functions to access Aurora"
  value       = aws_iam_role.lambda_aurora_role.arn
}

output "data_api_enabled" {
  description = "Status of Data API"
  value       = "Enabled"
}

output "setup_instructions" {
  description = "Instructions for setting up the database"
  value = <<-EOT
    
    ✅ Aurora Serverless v2 cluster deployed successfully!
    
    Database Details:
    - Cluster: ${data.aws_rds_cluster.aurora.cluster_identifier}
    - Database: alex
    - Data API: Enabled
    
    Add the following to your .env file:
    AURORA_CLUSTER_ARN=${data.aws_rds_cluster.aurora.arn}
    AURORA_SECRET_ARN=${data.aws_secretsmanager_secret.db_credentials.arn}
    
    Test the Data API connection:
    aws rds-data execute-statement \
      --resource-arn ${data.aws_rds_cluster.aurora.arn} \
      --secret-arn ${data.aws_secretsmanager_secret.db_credentials.arn} \
      --database alex \
      --sql "SELECT version()"
    
    To set up the database schema:
    cd backend/database
    uv run run_migrations.py
    
    To load sample data:
    uv run reset_db.py --with-test-data
    
    💰 Cost Management:
    - This cluster uses Express Configuration (auto-managed scaling)
  EOT
}