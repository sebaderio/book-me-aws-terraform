################################################################################
# General
################################################################################

# CloudFront supports only custom ACM certificates created in the us-east-1 region.
# There was also an issue when I later tried to configure the CloudFront distribution
# with s3 bucket in eu-central-1 region as origin. Not sure what was the root cause,
# but I was getting "CloudFront wasn’t able to connect to the origin" error.
# The easiest was to simply hardcode the region to the one in which everything works fine.
provider "aws" {
  region = "us-east-1"
}


################################################################################
# S3 bucket with CloudFront distribution to host React client app
################################################################################

# Configuring CloudFront for the bucket hosting client app is the easiest way to configure
# SSL certificate for the client app. Additionally, your app can be accessed by clients faster
# thanks to the distribution around the world based on the price class specified.
# Useful resource: https://adamtheautomator.com/aws-s3-static-ssl-website/
# I have tried to configure SSL certificate straight for the S3 bucket, but I gave up.
# There were problems related to the fact that s3 does not have a full HTTPS support.
# *Of course people found some workarounds, but...
# There is a lot of content discussing the topic in the web. Google it if you are interested.

data "aws_iam_policy_document" "client_app_bucket_policy" {
  statement {
    sid = "GetBucketObjectForPublic"
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.client_app_bucket_name}",
      "arn:aws:s3:::${var.client_app_bucket_name}/*",
    ]
  }
}

module "client_app_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.6.1"

  bucket = var.client_app_bucket_name

  force_destroy = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.client_app_bucket_policy.json

  website = {
    index_document = "index.html"
    # TODO mention this in README.
    # Easy, hacky way to make react-router work correctly. error_document should be set to 50x.html.
    # This solution affects the SEO in a really bad way.
    # There is a better solution that requires s3 bucket redirection configuration and small code changes.
    # https://stackoverflow.com/questions/51218979/react-router-doesnt-work-in-aws-s3-bucket
    # https://via.studio/journal/hosting-a-reactjs-app-with-routing-on-aws-s3
    error_document = "index.html"
  }
}

module "client_app_acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.3.1"

  domain_name = var.client_app_domain_name
  zone_id     = var.route53_zone_id
}

locals {
  cloudfront_distribution_s3_bucket_origin = "ClientAppS3Origin"
}

module "client_app_cloudfront_distribution" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 3.2.0"

  # Some values configured here are quite hard to understand when looking at the code below.
  # Check the CloudFront AWS module source code and AWS provider docs for resources configured
  # in the CloudFront module to get more details.

  origin = {
    client_app_s3_bucket = { # with origin access control settings (recommended)
      domain_name = module.client_app_s3_bucket.s3_bucket_website_endpoint
      origin_id   = local.cloudfront_distribution_s3_bucket_origin
      # Custom origin config is needed when you want to specify s3 bucket website endpoint as `domain_name`
      # parameter instead of the s3 bucket domain name. Without website endpoint configured I was getting
      # Access Denied when trying to access the content.
      custom_origin_config = {
        http_port                = 80
        https_port               = 443
        origin_protocol_policy   = "http-only"
        origin_ssl_protocols     = ["TLSv1.2"]
        origin_keepalive_timeout = 5
        origin_read_timeout      = 30
      }
    }
  }

  # Only North America (USA, Canada, Mexico), Europe and Israel.
  price_class = "PriceClass_100"

  aliases = [var.client_app_domain_name]
  viewer_certificate = {
    acm_certificate_arn      = module.client_app_acm.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  default_cache_behavior = {
    target_origin_id       = local.cloudfront_distribution_s3_bucket_origin
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    query_string           = true
    # After push of the new version of the app to the s3 bucket, you should create CloudFront distribution
    # invalidation to force CloudFront to fetch the newest version of the app on all edge locations immediately.
    # You can e.g configure CloudWatch event that creates invalidation each time when there is a push to the bucket.
    default_ttl = 86400 # 1 day
    min_ttl = 3600 # 1 hour
    max_ttl = 172800 # 2 days
  }
}

resource "aws_route53_record" "client_app" {
  zone_id = var.route53_zone_id
  name    = var.client_app_domain_name
  type    = "A"

  alias {
    name                   = module.client_app_cloudfront_distribution.cloudfront_distribution_domain_name
    zone_id                = module.client_app_cloudfront_distribution.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}
