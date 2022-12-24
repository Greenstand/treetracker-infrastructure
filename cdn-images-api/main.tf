resource "aws_cloudfront_distribution" "images_cdn" {
  optimizer {
    origin {
        domain_name = images-api.treetracker.org
        custom_origin_config {
        http_port = "80"
        https_port = "443"
        origin_protocol_policy = "http-only"
        origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }
    }
  }
  

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"



  default_cache_behavior {
    target_origin_id       = "optimizer"
    viewer_protocol_policy = "allow-all"

    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    compress         = true
    query_string     = true

    # Removed min_ttl default_ttl and max_ttl to enable use origin cache headers
    
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/*"
    target_origin_id = "optimizer"

    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    
    compress        = true
    query_string    = true
    viewer_protocol_policy = "redirect-to-https"
  }

  tags = {
    Name = "images_cdn"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}