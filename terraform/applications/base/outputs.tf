################################################################################
# VPC
################################################################################

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "vpc_public_subnets" {
  value = module.vpc.public_subnets
}

output "vpc_private_subnets" {
  value = module.vpc.private_subnets
}

output "vpc_database_subnets" {
  value = module.vpc.database_subnets
}

output "vpc_elasticache_subnets" {
  value = module.vpc.elasticache_subnets
}


################################################################################
# Postgres RDS
################################################################################

output "db_address" {
  value = module.db.db_instance_address
}

output "db_endpoint" {
  value = module.db.db_instance_endpoint
}

output "db_port" {
  value = module.db.db_instance_port
}

output "db_name" {
  value = module.db.db_instance_name
}

output "db_master_username" {
  value     = module.db.db_instance_username
  sensitive = true
}

output "db_master_password" {
  value     = module.db.db_instance_password
  sensitive = true
}


################################################################################
# Elasticache Redis
################################################################################

output "redis_primary_endpoint_address" {
  value = module.redis.elasticache_replication_group_primary_endpoint_address
}

output "redis_reader_endpoint_address" {
  value = module.redis.elasticache_replication_group_reader_endpoint_address
}

output "redis_port" {
  value = module.redis.elasticache_port
}

output "redis_auth_token" {
  value     = module.redis.elasticache_auth_token
  sensitive = true
}


################################################################################
# ECR for backend image
################################################################################

output "backend_ecr_repository_url" {
  value = module.backend_ecr.repository_url
}


################################################################################
# S3 bucket to store terraform state, configuration and secrets
################################################################################

output "config_s3_bucket_arn" {
  value = module.config_s3_bucket.s3_bucket_arn
}


################################################################################
# S3 bucket to store API static and media
################################################################################

output "static_media_s3_bucket_arn" {
  value = module.static_media_s3_bucket.s3_bucket_arn
}
