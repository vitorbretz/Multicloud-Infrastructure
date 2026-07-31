# ==============================================================================
# AWS S3 STATIC WEBSITE RESOURCES
# ==============================================================================
# S3 bucket configuration for static website hosting
# Author: Vitor
# Created: 2026-07-31
# ==============================================================================

# S3 Bucket for Static Website
resource "aws_s3_bucket" "this" {
  bucket = var.aws_s3_website.bucket_name

  tags = merge(
    local.common_tags,
    {
      Name        = var.aws_s3_website.bucket_name
      Type        = "StaticWebsite"
      Provider    = "AWS"
      Service     = "S3"
      Purpose     = "Primary Website Hosting"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Public Access Block Configuration  
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket Policy for Public Read Access
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
      },
      {
        Sid    = "CloudFrontLogsWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.this.arn}/cloudfront-logs/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.this]
}

# Static Website Configuration
resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.aws_s3_website.website.index_document
  }

  error_document {
    key = var.aws_s3_website.website.error_document
  }
}