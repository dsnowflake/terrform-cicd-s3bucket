variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "acl_enabled" {
  description = "Controls whether ACLs are enabled for the bucket. Only set to true if you need to use an OAI."
  type        = bool
  default     = false
}
```modules/s3-bucket/main.tf`
```hcl
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  # This setting is required to allow CloudFront to write logs to the bucket.
  # When used as a CloudFront log bucket, the ACLs need to be enabled for log delivery.
  # The documentation says ACLs should be disabled for new buckets, but for log delivery, they must be enabled.
  # This is a known caveat with CloudFront logging.
  acl    = var.acl_enabled ? "log-delivery-write" : null

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
  # We block all public access by default, and CloudFront will use an OAI to access the files.
  # This is a key security measure.
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

```modules/s3-bucket/outputs.tf`
```hcl
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