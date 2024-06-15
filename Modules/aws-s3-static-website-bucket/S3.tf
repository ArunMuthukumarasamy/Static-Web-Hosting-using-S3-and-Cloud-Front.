terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


resource "aws_s3_bucket" "exam" {
  bucket = var.bucket_name
  tags = {
    Name = "exam"
  }
}

resource "aws_s3_bucket_public_access_block" "exam-public" {
  bucket = aws_s3_bucket.exam.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "exam" {
  bucket = aws_s3_bucket.exam.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Allows CloudFront to access the S3 bucket"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.exam.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.exam.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.exam.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/error.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/error.html"
  }
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.s3_distribution.id
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.exam.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          AWS = "*"
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.exam.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_object" "index" {
  bucket      = aws_s3_bucket.exam.bucket
  key         = "index.html"
  source      = "C:\\Users\\rohan\\Downloads\\cloudfront\\Modules\\aws-s3-static-website-bucket\\index.html"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "error" {
  bucket      = aws_s3_bucket.exam.bucket
  key         = "error.html"
  source      = "C:\\Users\\rohan\\Downloads\\cloudfront\\Modules\\aws-s3-static-website-bucket\\error.html"
  content_type = "text/html"
}
