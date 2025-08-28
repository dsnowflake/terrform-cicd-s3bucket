variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "acl_enabled" {
  description = "Controls whether ACLs are enabled for the bucket. Only set to true if you need to use an OAI."
  type        = bool
  default     = false
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  # This resource blocks public access, regardless of the object_ownership setting.
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# This resource configures the bucket's object ownership settings.
# It is created only for the logs bucket, as indicated by the count argument.
resource "aws_s3_bucket_ownership_controls" "this" {
  count  = var.acl_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

# This resource manages the ACL and is created only for the logs bucket.
resource "aws_s3_bucket_acl" "this" {
  count  = var.acl_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id
  acl    = "log-delivery-write"
}

output "bucket_id" {
  description = "The ID of the S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The domain name of the S3 bucket."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
