# TODO
# - implement a way to pass parameters and secrets to containers
# - make django app working with new resources like s3, user session in redis
# - make sure you follow security good practices
# - Fix TLS certificate and domain, seems that it does not work now
# - configure autoscaling of API service according to good practices, e.g CPU usage
# - configure CI/CD with github actions, build docker image, push to registry, maybe trigger deployment automatically
# - Improve logs configuration, add logs saving to relevant services, maybe save in s3 instead of CW
# - configure allowed hosts, csrf etc. for django api container
# - configure health checks for django api container
# - configure s3 bucket as a remote state
# - refactor the entire configuration
# - enjoy the journey

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

  create_database_subnet_group = true
  # Subnet group is created in the redis module, but subnets are created in this module.
  create_elasticache_subnet_group = false

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


# ################################################################################
# # Postgres RDS
# ################################################################################

# module "db" {
#   source  = "terraform-aws-modules/rds/aws"
#   version = "~> 5.2.3"

#   identifier = var.rds_db_id

#   # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
#   engine               = "postgres"
#   engine_version       = "14"
#   family               = "postgres14" # DB parameter group
#   major_engine_version = "14"         # DB option group
#   instance_class       = "db.t4g.micro"

#   allocated_storage     = 5
#   max_allocated_storage = 20

#   # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
#   # "Error creating DB Instance: InvalidParameterValue: MasterUsername
#   # user cannot be used as it is a reserved word used by the engine"
#   db_name  = var.rds_db_name
#   username = var.rds_db_username
#   # By default random password is generated for the master user.
#   port = var.rds_db_port

#   db_subnet_group_name   = module.vpc.database_subnet_group
#   vpc_security_group_ids = [module.db_security_group.security_group_id]

#   maintenance_window              = "Mon:00:00-Mon:03:00"
#   backup_window                   = "03:00-06:00"
#   enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
#   create_cloudwatch_log_group     = true

#   backup_retention_period = 1
#   skip_final_snapshot     = true
#   deletion_protection     = false

#   performance_insights_enabled          = true
#   performance_insights_retention_period = 7
#   create_monitoring_role                = true
#   monitoring_interval                   = 60
#   monitoring_role_name                  = "${var.rds_db_id}-rds-role"
#   monitoring_role_use_name_prefix       = true

#   parameters = [
#     {
#       name  = "autovacuum"
#       value = 1
#     },
#     {
#       name  = "client_encoding"
#       value = "utf8"
#     }
#   ]
# }

# module "db_security_group" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "~> 4.17.1"

#   name        = "${var.rds_db_id}-rds"
#   description = "PostgreSQL security group"
#   vpc_id      = module.vpc.vpc_id

#   # ingress
#   ingress_with_cidr_blocks = [
#     {
#       from_port   = var.rds_db_port
#       to_port     = var.rds_db_port
#       protocol    = "tcp"
#       description = "PostgreSQL access from within VPC"
#       cidr_blocks = module.vpc.vpc_cidr_block
#     },
#   ]
# }


# ################################################################################
# # Elasticache Redis
# ################################################################################

# module "redis" {
#   source  = "umotif-public/elasticache-redis/aws"
#   version = "~> 3.2.0"

#   name_prefix        = var.redis_db_id
#   num_cache_clusters = 1
#   node_type          = "cache.t3.micro"
#   engine_version     = "7.0"
#   family             = "redis7"

#   maintenance_window       = "mon:00:00-mon:02:00"
#   snapshot_window          = "02:00-04:00"
#   snapshot_retention_limit = 7

#   apply_immediately          = true
#   automatic_failover_enabled = false

#   at_rest_encryption_enabled = false
#   transit_encryption_enabled = false

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.elasticache_subnets

#   allowed_security_groups = [module.vpc.default_security_group_id]
#   ingress_cidr_blocks     = [module.vpc.vpc_cidr_block]
# }


# ################################################################################
# # ALB
# ################################################################################

# module "alb_security_group" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "~> 4.17.1"

#   name        = var.alb_id
#   description = "Security group for ALB"
#   vpc_id      = module.vpc.vpc_id

#   ingress_cidr_blocks = ["0.0.0.0/0"]
#   ingress_rules       = ["http-80-tcp", "https-443-tcp", "all-icmp"]
#   egress_rules        = ["all-all"]
# }

# # When checking in the AWS console there is only one DNS record for both certs. It seems that when provisioning
# # Terraform requests one certificate for both domain names specified below. See the note in the official AWS docs.
# # With current setup the wildcard cert is redundant, but I left it to remember how such cases are handled.
# # https://docs.aws.amazon.com/acm/latest/userguide/acm-certificate.html#:~:text=a%20public%20certificate.-,wildcard%20names,-ACM%20allows%20you
# module "alb_acm" {
#   source  = "terraform-aws-modules/acm/aws"
#   version = "~> 4.3.1"

#   domain_name = var.acm_domain_name
#   zone_id     = var.route53_zone_id
# }

# module "alb_wildcard_cert" {
#   source  = "terraform-aws-modules/acm/aws"
#   version = "~> 4.3.1"

#   domain_name = "*.${var.acm_domain_name}"
#   zone_id     = var.route53_zone_id
# }

# module "alb" {
#   source  = "terraform-aws-modules/alb/aws"
#   version = "~> 8.2.1"

#   name = var.alb_id

#   vpc_id          = module.vpc.vpc_id
#   security_groups = [module.alb_security_group.security_group_id]
#   subnets         = module.vpc.public_subnets

#   http_tcp_listeners = [
#     {
#       port        = 80
#       protocol    = "HTTP"
#       action_type = "redirect"
#       redirect = {
#         port        = "443"
#         protocol    = "HTTPS"
#         status_code = "HTTP_301"
#       }
#     }
#   ]

#   # Enabled sticky session to make websockets API working correctly.
#   # When having multiple target groups you should also configure stickiness on listeners level.
#   target_groups = [
#     {
#       name                 = "${var.alb_id}-tg"
#       backend_protocol     = "HTTP"
#       backend_port         = 8000
#       target_type          = "ip"
#       deregistration_delay = 90
#       stickiness = {
#         enabled         = true
#         cookie_duration = var.alb_api_target_group_stickiness_duration
#         type            = "lb_cookie"
#       }
#     }
#   ]

#   https_listeners = [
#     {
#       port               = 443
#       protocol           = "HTTPS"
#       certificate_arn    = module.alb_acm.acm_certificate_arn
#       target_group_index = 0

#     },
#   ]

#   extra_ssl_certs = [
#     {
#       https_listener_index = 0
#       certificate_arn      = module.alb_wildcard_cert.acm_certificate_arn
#     }
#   ]
# }


################################################################################
# S3 bucket to store API static and media
################################################################################

data "aws_iam_policy_document" "static_media_bucket_policy" {
  statement {
    sid = "ListObjectsInBucketFromFargateTasks"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.static_media_bucket_name}",
    ]
  }

  statement {
    sid = "FullPermissionOnBucketObjectForFargateTasks"
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }

    actions = [
      "s3:*Object",
    ]

    resources = [
      "arn:aws:s3:::${var.static_media_bucket_name}/*",
    ]
  }


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
      "arn:aws:s3:::${var.static_media_bucket_name}/*",
    ]
  }
}

# TODO Confirm if bucket policies are strict enough. Implicit deny rule should work fine...
module "static_media_s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.static_media_bucket_name

  force_destroy = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.static_media_bucket_policy.json
}


################################################################################
# VPC Endpoints
################################################################################

# It makes no sense to pay for NAT gateway when there is a way to not go out of VPC
# TODO vpc endpoints - ecr, s3,


# ################################################################################
# # ECS
# ################################################################################

# module "ecs" {
#   source  = "terraform-aws-modules/ecs/aws"
#   version = "~> 4.1.2"

#   cluster_name = var.ecs_cluster_id

#   cluster_configuration = {
#     execute_command_configuration = {
#       logging = "OVERRIDE"
#       log_configuration = {
#         # You can set a simple string and ECS will create the CloudWatch log group for you
#         # or you can create the resource yourself to better manage retetion, tagging, etc.
#         # TODO Determine if the cloud watch group is created. How about permissions to CloudWatch?
#         cloud_watch_log_group_name = "/aws/ecs/${var.ecs_cluster_id}"
#       }
#     }
#   }

#   fargate_capacity_providers = {
#     FARGATE = {
#       default_capacity_provider_strategy = {
#         weight = 50
#         base   = 1
#       }
#     }
#     FARGATE_SPOT = {
#       default_capacity_provider_strategy = {
#         weight = 50
#       }
#     }
#   }
# }

# # TODO Add autoscaling policy based on the CPU usage
# module "service_api" {
#   source = "./service-api"

#   vpc_id              = module.vpc.vpc_id
#   vpc_cidr_block      = module.vpc.vpc_cidr_block
#   cluster_id          = module.ecs.cluster_id
#   task_image          = var.api_task_image
#   name                = var.api_service_name
#   port                = 8000
#   cpu                 = var.api_service_cpu
#   memory              = var.api_service_memory
#   subnets             = module.vpc.private_subnets
#   lb_target_group_arn = module.alb.target_group_arns[0]
# }
