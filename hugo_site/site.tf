# Create bucket policy
# Create bucket for root hostname
# Create bucket for www hostname
# Add bucket policy for root hostname
# Create CloudFront distributions for root and www hostnames
# Create origin access identity for root hostname
# Create Route53 DNS records for root and www hostnames

data "aws_acm_certificate" "site" {
  domain = var.site_name
}

data "aws_iam_policy_document" "bucket_root" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    resources = [
      "arn:aws:s3:::${var.site_name}/*",
    ]
  }
}

data "aws_route53_zone" "site" {
  name = "${var.site_name}."
}

resource "aws_cloudfront_distribution" "root" {
  aliases             = [var.site_name]
  default_root_object = "index.html"
  enabled             = "true"
  is_ipv6_enabled     = "true"
  price_class         = var.cloudfront_price_class

  tags = {
    var.tag_name = var.site_name
  }

  custom_error_response {
    error_code         = "404"
    response_code      = "404"
    response_page_path = "/404.html"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    default_ttl            = 3600
    max_ttl                = 86400
    min_ttl                = 3600
    target_origin_id       = "origin.${var.site_name}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name = aws_s3_bucket.root.website_endpoint
    origin_id   = "origin.${var.site_name}"

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.site.arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_cloudfront_distribution" "www" {
  aliases         = ["www.${var.site_name}"]
  enabled         = "true"
  is_ipv6_enabled = "true"
  price_class     = var.cloudfront_price_class

  tags = {
    var.tag_name = var.site_name
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    default_ttl            = 3600
    max_ttl                = 86400
    min_ttl                = 3600
    target_origin_id       = "origin.www.${var.site_name}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name = aws_s3_bucket.www.website_endpoint
    origin_id   = "origin.www.${var.site_name}"

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.site.arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_cloudfront_origin_access_identity" "root" {
}

resource "aws_route53_record" "root_ipv4" {
  zone_id = data.aws_route53_zone.site.id

  name = var.site_name
  type = "A"

  alias {
    name                   = aws_cloudfront_distribution.root.domain_name
    zone_id                = aws_cloudfront_distribution.root.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root_ipv6" {
  zone_id = data.aws_route53_zone.site.id

  name = var.site_name
  type = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.root.domain_name
    zone_id                = aws_cloudfront_distribution.root.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_ipv4" {
  zone_id = data.aws_route53_zone.site.id

  name = "www.${var.site_name}"
  type = "A"

  alias {
    name                   = aws_cloudfront_distribution.www.domain_name
    zone_id                = aws_cloudfront_distribution.www.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_ipv6" {
  zone_id = data.aws_route53_zone.site.id

  name = "www.${var.site_name}"
  type = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.www.domain_name
    zone_id                = aws_cloudfront_distribution.www.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket" "root" {
  bucket        = var.site_name
  acl           = "public-read"
  force_destroy = true

  tags = {
    var.tag_name = var.site_name
  }

  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket" "www" {
  bucket        = "www.${var.site_name}"
  acl           = "public-read"
  force_destroy = true

  tags = {
    var.tag_name = var.site_name
  }

  website {
    redirect_all_requests_to = "https://${var.site_name}"
  }
}

resource "aws_s3_bucket_policy" "root" {
  bucket = aws_s3_bucket.root.id
  policy = data.aws_iam_policy_document.bucket_root.json
}

