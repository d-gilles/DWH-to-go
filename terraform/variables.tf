# General

variable "environment" {
    description = "Environment name"
    default     = "dev"
}

# AWS
variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "credential_file" {
  description = "Path to credential file"
  default     = "~/.aws/cred_terraform"
}

variable "aws_terraform_user" {
  description = "User name that is used by terraform"
  default     = "terraform_user"
}

variable "s3_backend_bucket_name" {
  description = "S3 Bucket for Terraform Backend"
  default     = "terraform-backend-bucket"
}

variable "s3_data_lake_bucket_name" {
    description = "S3 Bucket for logs"
    default     = "terraform-logs-bucket"
}

variable "s3_log_bucket_name" {
    description = "S3 Bucket for logs"
    default     = "terraform-logs-bucket"
}

variable "dynamodb_table_name" {
  description = "DynamoDB Table for state locking"
  default     = "terraform-locks"
}


  
