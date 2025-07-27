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
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = "adam-secure-logs-bucket"
    target_prefix = "log/"
  }

  lifecycle_rule {
    id      = "log"
    enabled = true

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      days = 30
    }
  }

  replication_configuration {
    role = aws_iam_role.replication_role.arn

    rules {
      id     = "replication"
      status = "Enabled"

      destination {
        bucket        = "arn:aws:s3:::replica-bucket"
        storage_class = "STANDARD"
      }

      filter {}
    }
  }

  tags = {
    Owner       = "adam"
    Environment = "dev"
  }
}

resource "aws_s3_bucket" "secure_logs_bucket" {
  bucket        = "adam-secure-logs-bucket"
  force_destroy = true
}

resource "aws_s3_bucket" "replica_bucket" {
  bucket        = "replica-bucket"
  force_destroy = true
}

resource "aws_iam_role" "replication_role" {
  name = "replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "s3.amazonaws.com"
      }
    }]
  })
}
