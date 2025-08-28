variable "env" {
  description = "The environment name (e.g., devel, stage, prod)."
  type        = string
}
```modules/app-infra/main.tf`
```hcl
# Create the S3 bucket for the application's static files.
# It uses the s3-bucket module we created earlier.
module "app_s3_bucket" {
  source      = "../s3-bucket"
  bucket_name = "app-${var.env}-s3-bucket"
}

# Create a separate S3 bucket for CloudFront access logs.
module "logs_s3_bucket" {
  source      = "../s3-bucket"
  bucket_name = "app-${var.env}-cloudfront-logs"
  # This is required for CloudFront log delivery.
  acl_enabled = true
}

# Create an Origin Access Identity (OAI) for CloudFront to access the S3 bucket.
resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "OAI for ${var.env} CloudFront distribution"
}

# Configure the S3 bucket policy to allow only the CloudFront OAI to read objects.
resource "aws_s3_bucket_policy" "this" {
  bucket = module.app_s3_bucket.bucket_id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowCloudFrontOAI",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.this.id}"
        },
        "Action" : "s3:GetObject",
        "Resource" : "${module.app_s3_bucket.bucket_arn}/*"
      }
    ]
  })
}

# Create the CloudFront distribution to serve the S3 bucket content.
resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name = module.app_s3_bucket.bucket_domain_name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.env} environment"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false
      headers      = []
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Configure logging to the dedicated S3 log bucket.
  logging_config {
    bucket = module.logs_s3_bucket.bucket_domain_name
    prefix = "cloudfront-logs/"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

```modules/app-infra/outputs.tf`
```hcl
output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_arn" {
  description = "The ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.arn
}