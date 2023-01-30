################################################################################
# General
################################################################################

variable "region" {
  type    = string
  default = "eu-central-1"
}


################################################################################
# VPC
################################################################################

variable "vpc_id" {
  type        = string
  description = "Name of the existing VPC in which resources should be provisioned."
}

variable "vpc_cidr_block" {
  type        = string
  description = "Cidr block of the existing VPC in which resources should be provisioned."
}

variable "vpc_public_subnets" {
  type        = list(string)
  description = "List of existing public subnets in the VPC."
}

variable "vpc_private_subnets" {
  type        = list(string)
  description = "List of existing private subnets in the VPC."
}


################################################################################
# ALB
################################################################################

variable "alb_id" {
  type    = string
  default = "book-me-prod-alb"
}

variable "acm_domain_name" {
  type    = string
  default = "apiv2.bookme.tk"
}

variable "route53_zone_id" {
  type = string
  # TODO Remove the default value
  default     = "Z02587991HESUSK03JP5P"
  description = "ID of the existing Route53 hosted zone."
}

variable "alb_api_target_group_stickiness_duration" {
  type    = number
  default = 60
}


################################################################################
# ECS
################################################################################

variable "ecs_cluster_id" {
  type    = string
  default = "book-me-prod-ecs-cluster"
}

variable "api_service_name" {
  type    = string
  default = "book-me-prod-api"
}

variable "api_task_image" {
  type        = string
  default     = "crccheck/hello-world:latest"
  description = "Ultimately it should be the task image stored in ECR repository."
}

variable "api_task_cmd" {
  type    = list(string)
  default = ["sh", "-c", "daphne --bind 0.0.0.0 core.asgi:application && python manage.py runworker -v2"]
}

variable "api_service_cpu" {
  type    = number
  default = 256
}

variable "api_service_memory" {
  type    = number
  default = 512
}

variable "api_config_bucket_name" {
  type        = string
  default     = "book-me-prod-config"
  description = "Name of the s3 bucket where file with api service settings and secrets resides."
}

variable "api_config_file_path" {
  type        = string
  default     = "/service-config/api/production.env"
  description = "Path to the file with api service settings and secrets in the config s3 bucket."
  # TODO add validation -> min length 5 (/.env), starts with "/", ends with ".env"
}
