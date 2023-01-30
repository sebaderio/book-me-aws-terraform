################################################################################
# S3 bucket with CloudFront distribution to host React client app
################################################################################

variable "client_app_bucket_name" {
  type    = string
  default = "book-me-prod-client-app"
}

variable "route53_zone_id" {
  type        = string
  default     = "Z02587991HESUSK03JP5P"
  description = "ID of the existing Route53 hosted zone."
}

variable "client_app_domain_name" {
  type    = string
  default = "app.bookme.tk"
}
