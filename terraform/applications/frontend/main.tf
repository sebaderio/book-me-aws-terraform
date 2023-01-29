################################################################################
# S3 bucket to host React client app
################################################################################

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

resource "aws_route53_record" "client_app" {
  zone_id = var.route53_zone_id
  name    = var.client_app_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [module.client_app_s3_bucket.s3_bucket_website_endpoint]
}
