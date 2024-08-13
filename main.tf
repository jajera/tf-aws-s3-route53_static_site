resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  name  = random_string.suffix.result
  node1 = "node1.${local.name}.${var.domain}"
  node2 = "node2.${local.name}.${var.domain}"
}

resource "aws_s3_bucket" "node1" {
  bucket        = local.node1
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "node1" {
  bucket = aws_s3_bucket.node1.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "node1" {
  bucket = aws_s3_bucket.node1.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "node1" {
  bucket = aws_s3_bucket.node1.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "node1" {
  bucket                  = aws_s3_bucket.node1.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "node1" {
  bucket = aws_s3_bucket.node1.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.node1,
    aws_s3_bucket_public_access_block.node1,
  ]
}

resource "aws_s3_object" "node1_index_html" {
  bucket       = aws_s3_bucket.node1.bucket
  key          = "index.html"
  content_type = "text/html"
  content      = <<EOF
<!doctype html>
<html>
<head>
    <title>Hello!</title>
</head>
<body>
    <h1>Hello, World!</h1>
</body>
</html>
EOF
}

resource "aws_s3_bucket_policy" "node1_allow_public_access" {
  bucket = aws_s3_bucket.node1.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.node1.arn}/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.node1,
    aws_s3_bucket_acl.node1,
    aws_s3_bucket_website_configuration.node1,
    aws_s3_bucket_public_access_block.node1
  ]
}

resource "aws_s3_bucket" "node2" {
  bucket        = local.node2
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "node2" {
  bucket = aws_s3_bucket.node2.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "node2" {
  bucket = aws_s3_bucket.node2.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "node2" {
  bucket = aws_s3_bucket.node2.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "node2" {
  bucket                  = aws_s3_bucket.node2.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "node2" {
  bucket = aws_s3_bucket.node2.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.node2,
    aws_s3_bucket_public_access_block.node2,
  ]
}

resource "aws_s3_object" "node2_index_html" {
  bucket       = aws_s3_bucket.node2.bucket
  key          = "index.html"
  content_type = "text/html"
  content      = <<EOF
<!doctype html>
<html>
<head>
    <title>Hello!</title>
</head>
<body>
    <h1>Hello, World!</h1>
</body>
</html>
EOF
}

resource "aws_s3_bucket_policy" "node2_allow_public_access" {
  bucket = aws_s3_bucket.node2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.node2.arn}/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.node2,
    aws_s3_bucket_acl.node2,
    aws_s3_bucket_website_configuration.node2,
    aws_s3_bucket_public_access_block.node2
  ]
}

data "aws_route53_zone" "example" {
  name = var.domain
}

resource "aws_route53_record" "node1" {
  zone_id = data.aws_route53_zone.example.id
  name    = local.node1
  type    = "CNAME"

  alias {
    name                   = aws_s3_bucket_website_configuration.node1.website_endpoint
    zone_id                = aws_s3_bucket.node1.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "node2" {
  zone_id = data.aws_route53_zone.example.id
  name    = local.node2
  type    = "CNAME"

  alias {
    name                   = aws_s3_bucket_website_configuration.node2.website_endpoint
    zone_id                = aws_s3_bucket.node2.hosted_zone_id
    evaluate_target_health = true
  }
}

output "node1_s3_website_url" {
  value = "http://${aws_s3_bucket.node1.bucket}.s3-website.${data.aws_region.current.name}.amazonaws.com"
}

output "node1_route53_website_url" {
  value = "http://${local.node1}"
}

output "node2_s3_website_url" {
  value = "http://${aws_s3_bucket.node2.bucket}.s3-website.${data.aws_region.current.name}.amazonaws.com"
}

output "node2_route53_website_url" {
  value = "http://${local.node2}"
}
