# S3-Bucket erstellen
resource "aws_s3_bucket" "terraform_data-lake" {
  bucket = var.s3_data_lake_bucket_name
  tags = {
    Name        = "terraform-data-lake-bucket"
    Environment = var.environment
  }
}

# "staging"-Ordner im Bucket erstellen
resource "aws_s3_object" "staging_placeholder" {
  bucket = aws_s3_bucket.terraform_data-lake.bucket
  key    = "staging/" 
  content = ""
}
