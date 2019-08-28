# In order to create a static website with minimum infrastracture effort and cost, I will use below resources: "this solution will be build on AWS cloud"
#   1- AWS code commit as SCM and Repo for version controlling. (we can use any other Git provider)
#   2- CodePipeline to update the changes from SCM(source Repo) to S3 bucket.
#   3- S3 bucket to host the static content.
#   4- CloudFront for Secure connection to S3 bucket.
#   5- AWS Certificate Manager to issue SSL certificate.

### I will use terraform to build this solution.## this can achieved using cloudformation and as well using aws cli and portal.
variable "site_name" {
  default = "test.com"
  description = "My site"
}

provider "aws" {
  version    = "~> 2.0"
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}
#   1- Create AWS S3 bucket to host the static content
#   The main website we want to build is test.com

resource "aws_s3_bucket" "website" {
    bucket = "www.${var.site_name}"
    website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

#AWS cloudfront origin Access

resource "aws_cloudfront_origin_access_identity" "access" {
  comment = "cloudfront origin access identity"
}

# S3 bucket policy to harden the access only from cloudfront
resource "aws_s3_bucket_policy" "policy" {
  bucket = "${aws_s3_bucket.website.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "BUCKETPOLICY",
  "Statement": [
    {
      "Sid": "OnlyCloudfrontReadAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.access.cloudfront_access_identity_path}"
      },
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "${aws_s3_bucket.website.arn}",
    }
  ]
}
POLICY
}


# cloudfront distribution
resource "aws_cloudfront_distribution" "website" {

  origin {
    domain_name = "${aws_s3_bucket.website.bucket_domain_name}"
    origin_id = "${var.site_name}-origin"
    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.access.cloudfront_access_identity_path}"
    }

  }  
  enabled = true
  aliases = ["${var.site_name}"]
  price_class = "PriceClass_100"
  default_root_object = "index.html"  
  default_cache_behavior {
    allowed_methods  = [ "GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.site_name}-origin"    
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 1000
    max_ttl                = 86400
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.cert.arn}"
    ssl_support_method  = "sni-only"
  }
}

#requesting and management of certificates from the Amazon Certificate Manager.
resource "aws_acm_certificate" "cert" {
  domain_name = "${var.site_name}"
  subject_alternative_names = ["www.${var.site_name}"]
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
##certificate validation using DNS
resource "aws_route53_record" "cert" {
    name = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
    type = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
    zone_id = "${aws_route53_zone.zone.id}"
    records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
    ttl = 60
}
# DNS Zone for DNS records
resource "aws_route53_zone" "zone" {
  name = "${var.site_name}"
}
# Create DNS records

resource "aws_route53_record" "dns" {
  zone_id = "${aws_route53_zone.zone.zone_id}"
  name = "www.${var.site_name}"
  type = "A"
  alias {
    name = "${aws_cloudfront_distribution.website.domain_name}"
    zone_id  = "${aws_cloudfront_distribution.website.hosted_zone_id}"
    evaluate_target_health = false
  }
}


