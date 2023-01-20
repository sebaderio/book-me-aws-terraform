
provider "aws" {
  region = var.region
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.19.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs                 = var.vpc_azs
  private_subnets     = var.vpc_private_subnets
  public_subnets      = var.vpc_public_subnets
  database_subnets    = var.vpc_database_subnets
  elasticache_subnets = var.vpc_elasticache_subnets

  create_database_subnet_group    = true
  create_elasticache_subnet_group = true

  # Default NACL, RT and SG configured through the AWS VPC terraform module are a bit different
  # than the NACL, RT and SG configured automatically by AWC when creating the VPC.
  # Resources created with the terraform module are an improved version of the AWS created ones. Just use it.

  # Default NACL allows all the inbound and outbound traffic.
  # Subnets not having the dedicated NACL configured are associated with the default NACL.
  manage_default_network_acl = true
  default_network_acl_tags   = { Name = "${var.vpc_name}-default" }

  # Default RT have only a rule allowing the traffic within the VPC.
  # According to the docs, subnets not having the route table association are associated with the default RT.
  manage_default_route_table = true
  default_route_table_tags   = { Name = "${var.vpc_name}-default" }

  # If you don't specify a security group when you launch an instance, the instance is automatically
  # associated with the default security group for the VPC.
  # This default SG does not have inbound and outbound rules configured. All the traffic is blocked.
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${var.vpc_name}-default" }

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  # To save on NAT gateway costs single NAT gateway is used. For production environments AWS
  # recommends to have one NAT gateway per AZ. With the current setup when the AZ in which
  # there is our NAT gateway goes down, services in other AZs will not reach the Internet too.
  single_nat_gateway = true

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = {
    Name = var.vpc_name
  }

  vpc_tags = {
    Name = var.vpc_name
  }
}

################################################################################
# Postgres RDS
################################################################################

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 5.2.3"

  identifier = var.rds_db_id

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "14"
  family               = "postgres14" # DB parameter group
  major_engine_version = "14"         # DB option group
  instance_class       = "db.t4g.micro"

  allocated_storage     = 5
  max_allocated_storage = 20

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name  = var.rds_db_name
  username = var.rds_db_username
  # By default random password is generated for the master user.
  port = var.rds_db_port

  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.db_security_group.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "${var.rds_db_id}-rds-role"
  monitoring_role_use_name_prefix       = true

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]
}

module "db_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.17.1"

  name        = "${var.rds_db_id}-rds"
  description = "PostgreSQL security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = var.rds_db_port
      to_port     = var.rds_db_port
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]
}


# ################################################################################
# # Elasticache Redis
# ################################################################################

# module "redis" {
#   source = "cloudposse/elasticache-redis/aws"
#   version = "~> 0.49.0"

#   name = var.redis_db_id
#   vpc_id                           = module.vpc.vpc_id
#   allowed_security_group_ids       = [module.vpc.default_security_group_id]
#   elasticache_subnet_group_name    = module.vpc.elasticache_subnet_group
#   cluster_size                     = 1
#   instance_type                    = "cache.t3.micro"
#   engine_version                   = "7.0"
#   family                           = "redis7"
#   transit_encryption_enabled       = false

#   # Verify that we can safely change security groups (name changes forces new SG)
#   security_group_create_before_destroy = true
#   security_group_delete_timeout = "5m"
#   # This module creates the security group with all required permissions automatically. 
#   security_group_name                  = ["${var.redis_db_id}-cache"]

#   context = module.this.context
# }


# ################################################################################
# # ECR for API image
# ################################################################################


# ################################################################################
# # ALB
# ################################################################################


# ################################################################################
# # TLS Certificate for ALB
# ################################################################################


# ################################################################################
# # S3 bucket for API static and media content
# ################################################################################
