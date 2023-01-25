provider "aws" {
  region = var.region
}


data "aws_caller_identity" "current" {}


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


################################################################################
# VPC Endpoints
################################################################################

resource "aws_security_group" "vpc_endpoint" {
  name   = var.vpce_security_group_name
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids
  tags = {
    Name        = "s3-endpoint"
    Environment = "prod"
  }
}

# VPC endpoints work out of the box when you have DNS Hostnames and DNS Resolution
# enabled in the VPC. Also Enable DNS name option must be enabled in the VPC endpoint.
# This option is enabled by default when creating VPC endpoints through Terraform like below.
# VPC endpoints explanation: https://itnext.io/what-exactly-are-vpc-endpoints-and-why-they-need-real-inter-region-support-283a9987fe51.
resource "aws_vpc_endpoint" "dkr" {
  vpc_id              = module.vpc.vpc_id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]
  subnet_ids = module.vpc.private_subnets
  tags = {
    Name        = "dkr-endpoint"
    Environment = "prod"
  }
}

resource "aws_vpc_endpoint" "dkr_api" {
  vpc_id              = module.vpc.vpc_id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]
  subnet_ids = module.vpc.private_subnets
  tags = {
    Name        = "dkr-api-endpoint"
    Environment = "prod"
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


################################################################################
# Elasticache Redis
################################################################################

module "redis" {
  source  = "umotif-public/elasticache-redis/aws"
  version = "~> 3.2.0"

  name_prefix        = var.redis_db_id
  num_cache_clusters = 1
  node_type          = "cache.t3.micro"
  engine_version     = "7.0"
  family             = "redis7"

  maintenance_window       = "mon:00:00-mon:02:00"
  snapshot_window          = "02:00-04:00"
  snapshot_retention_limit = 7

  apply_immediately          = true
  automatic_failover_enabled = false

  # TODO add auth_token authentication
  at_rest_encryption_enabled = false
  transit_encryption_enabled = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.elasticache_subnets

  allowed_security_groups = [module.vpc.default_security_group_id]
  ingress_cidr_blocks     = [module.vpc.vpc_cidr_block]
}

################################################################################
# ECR for backend image
################################################################################

module "backend_ecr" {
  source = "terraform-aws-modules/ecr/aws"
  # TODO add version = "~> 1.5.1"

  repository_name = var.backend_repository_name

  # Only these users/roles can push images to the ECR repository. 
  repository_read_write_access_arns = [data.aws_caller_identity.current.arn]
  repository_force_delete           = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 20 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 20
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}


################################################################################
# S3 bucket to store terraform state, configuration and secrets
################################################################################

# TODO Check/enable encryption at rest and in transit?
module "config_s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  # TODO add version = "~> 3.6.1"

  bucket = var.config_bucket_name

  force_destroy = true
  versioning = {
    enabled = true
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


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
  # TODO add version = "~> 3.6.1"

  bucket = var.static_media_bucket_name

  force_destroy = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.static_media_bucket_policy.json
}


################################################################################
# EC2 Bastion
################################################################################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    # It needs to be Amazon 2 linux instance. Amazon 1 instances do not have
    # ec2-instance-connect installed, but it is needed to connect to the instance
    # from the AWS console.
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
}

module "bastion_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.17.1"

  name        = var.ec2_bastion_name
  description = "Security group for EC2 bastion"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp"]
  egress_rules        = ["all-all"]
}

locals {
  user_data = <<-EOT
  #!/bin/bash
  yum update -y
  yum install -y git amazon-linux-extras
  amazon-linux-extras install postgresql14
  EOT
}

module "ec2_bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.3.0"

  name = var.ec2_bastion_name

  ami               = data.aws_ami.amazon_linux.id
  instance_type     = var.ec2_bastion_instance_type
  availability_zone = element(module.vpc.azs, 0)
  subnet_id         = element(module.vpc.public_subnets, 0)

  vpc_security_group_ids      = [module.bastion_security_group.security_group_id]
  associate_public_ip_address = true

  user_data_base64            = base64encode(local.user_data)
  user_data_replace_on_change = true

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 bastion instance"
  iam_role_policies           = {}

  disable_api_stop = false
}
