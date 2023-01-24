output "repository_url" {
  value = module.ecr.repository_url
}

output "config_s3_bucket_arn" {
  value = module.config_s3_bucket.s3_bucket_arn
}
