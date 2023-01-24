variable "repository_name" {
  type        = string
  default     = "book-me-prod-api"
  description = "Name of the ECR repository to store API docker images."
}

variable "config_bucket_name" {
  type        = string
  default     = "book-me-config"
  description = "Name of the S3 bucket to store terraform state, app configuration and secrets."
}
