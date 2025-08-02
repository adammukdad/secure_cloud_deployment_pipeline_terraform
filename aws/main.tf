
provider "aws" {
  region = "us-east-2"
}

# S3 Bucket for primary storage
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "adam-secure-bucket-main"
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.secure_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption using KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = "alias/replica-s3-kms-key"
      sse_algorithm     = "aws:kms"
    }
  }
}

# Enable access logging
resource "aws_s3_bucket_logging" "logging" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = "adam-log-bucket-ohio"
  target_prefix = "log/"
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    id     = "expire-in-365-days"
    status = "Enabled"

    expiration {
      days = 365
    }
  }
}

# Replication configuration (requires IAM role and destination bucket)
resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [aws_s3_bucket_versioning.versioning]

  bucket = aws_s3_bucket.secure_bucket.id
  role   = aws_iam_role.replication_role.arn

  rules {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = "arn:aws:s3:::adam-replica-bucket-ohio"
      storage_class = "STANDARD"
    }

    filter {
      prefix = ""
    }

    delete_marker_replication {
      status = "Disabled"
    }
  }
}

# IAM Role for replication (placeholder block)
resource "aws_iam_role" "replication_role" {
  name = "replication_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Event notification placeholder
resource "aws_s3_bucket_notification" "notification" {
  bucket = aws_s3_bucket.secure_bucket.id
  # Uncomment and configure below if needed
  # topic {
  #   topic_arn = "arn:aws:sns:us-east-2:123456789012:example-topic"
  #   events    = ["s3:ObjectCreated:*"]
  # }
}
