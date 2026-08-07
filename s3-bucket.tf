resource "aws_s3_bucket" "this" {
  bucket = var.aws_s3_website.bucket_name

  tags = merge(
    local.common_tags,
    {
      Name = var.aws_s3_website.bucket_name
      Type = "StaticWebsite"
    }
  )

  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
