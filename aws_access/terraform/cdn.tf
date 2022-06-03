# Bucket serving the API images
data "aws_s3_bucket" "default" {
  bucket = "treetracker-dev-images"
}

resource "aws_cloudfront_distribution" "default" {
  origin {
    domain_name = aws_s3_bucket.default.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.default.bucket_regional_domain_name
  }

  origin {
    domain_name = aws_lb.default.dns_name
    origin_id   = aws_lb.default.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_protocol_policy = "http-only"
    }
  }

  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"

  # To define
  ordered_cache_behavior = [
    # {
    #   path_pattern           = "/static/*"
    #   target_origin_id       = "s3_one"
    #   viewer_protocol_policy = "redirect-to-https"

    #   allowed_methods = ["GET", "HEAD", "OPTIONS"]
    #   cached_methods  = ["GET", "HEAD"]
    #   compress        = true
    #   query_string    = true
    # }
  ]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.default.arn
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
