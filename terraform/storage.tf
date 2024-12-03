resource "aws_s3_bucket" "terraform_backend" {
  bucket = var.s3_backend_bucket_name
  tags = {
    Name        = "terraform-backend-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "terraform_logs" {
  bucket = var.s3_log_bucket_name
  tags = {
    Name        = "terraform-logs-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "terraform_data-lake" {
  bucket = var.s3_data_lake_bucket_name
  tags = {
    Name        = "terraform-data-lake-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_backend_encryption" {
  bucket = aws_s3_bucket.terraform_backend.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "terraform_backend_versioning" {
  bucket = aws_s3_bucket.terraform_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "terraform_backend_acl" {
  bucket = aws_s3_bucket.terraform_backend.id
  acl    = "private"
}  

