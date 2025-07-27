provider "aws" {
  region = "us-east-1"
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "secure_bucket" {
  bucket        = "adam-secure-bucket-${random_id.bucket_id.hex}"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = "alias/aws/s3"
      }
    }
  }

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/"
  }

  lifecycle_rule {
    id      = "expire-objects"
    enabled = true

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket" "log_bucket" {
  bucket        = "adam-log-bucket-${random_id.bucket_id.hex}"
  force_destroy = true
}
