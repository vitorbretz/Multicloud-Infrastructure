resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.aws_s3_website.website.index_document
  }

  error_document {
    key = var.aws_s3_website.website.error_document
  }
}
