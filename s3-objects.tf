resource "aws_s3_object" "html" {
  bucket       = aws_s3_bucket.this.id
  key          = local.website_files.html.key
  source       = local.website_files.html.source
  content_type = local.website_files.html.content_type
  etag         = filemd5(local.website_files.html.source)

  tags = merge(
    local.common_tags,
    {
      Name = local.website_files.html.key
      Type = "HTML"
    }
  )
}

resource "aws_s3_object" "css" {
  bucket       = aws_s3_bucket.this.id
  key          = local.website_files.css.key
  source       = local.website_files.css.source
  content_type = local.website_files.css.content_type
  etag         = filemd5(local.website_files.css.source)

  tags = merge(
    local.common_tags,
    {
      Name = local.website_files.css.key
      Type = "CSS"
    }
  )
}

resource "aws_s3_object" "js" {
  bucket       = aws_s3_bucket.this.id
  key          = local.website_files.js.key
  source       = local.website_files.js.source
  content_type = local.website_files.js.content_type
  etag         = filemd5(local.website_files.js.source)

  tags = merge(
    local.common_tags,
    {
      Name = local.website_files.js.key
      Type = "JavaScript"
    }
  )
}

resource "aws_s3_object" "assets" {
  for_each = fileset("${var.website_source_path}/assets", "*")

  bucket = aws_s3_bucket.this.id
  key    = "assets/${each.value}"
  source = "${var.website_source_path}/assets/${each.value}"
  content_type = lookup(
    local.content_type_mapping,
    element(split(".", each.value), length(split(".", each.value)) - 1),
    "application/octet-stream"
  )
  etag = filemd5("${var.website_source_path}/assets/${each.value}")

  tags = merge(
    local.common_tags,
    {
      Name = each.value
      Type = "Asset"
    }
  )
}
