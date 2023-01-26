################################################################################
# ALB
################################################################################

module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.17.1"

  name        = var.alb_id
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
}

# When checking in the AWS console there is only one DNS record for both certs. It seems that when provisioning
# Terraform requests one certificate for both domain names specified below. See the note in the official AWS docs.
# With current setup the wildcard cert is redundant, but I left it to remember how such cases are handled.
# https://docs.aws.amazon.com/acm/latest/userguide/acm-certificate.html#:~:text=a%20public%20certificate.-,wildcard%20names,-ACM%20allows%20you
module "alb_acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.3.1"

  domain_name = var.acm_domain_name
  zone_id     = var.route53_zone_id
}

module "alb_wildcard_cert" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.3.1"

  domain_name = "*.${var.acm_domain_name}"
  zone_id     = var.route53_zone_id
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.2.1"

  name = var.alb_id

  vpc_id          = var.vpc_id
  security_groups = [module.alb_security_group.security_group_id]
  subnets         = var.vpc_public_subnets

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  # Enabled sticky session to make websockets API working correctly.
  # When having multiple target groups you should also configure stickiness on listeners level.
  target_groups = [
    {
      name                 = "${var.alb_id}-tg"
      backend_protocol     = "HTTP"
      backend_port         = 8000
      target_type          = "ip"
      deregistration_delay = 90
      stickiness = {
        enabled         = true
        cookie_duration = var.alb_api_target_group_stickiness_duration
        type            = "lb_cookie"
      }
      health_check = {
        # There are more parameters to be configured, but not specified here because default values
        # should be fine. For more details check the official Terraform docs for aws_lb_target_group resource.
        path    = "/auth/ping" # works, but returns 301 when running Django with DEBUG=true, maybe `/auth/ping/?format=json` would be better
        matcher = "200-399"
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.alb_acm.acm_certificate_arn
      target_group_index = 0

    },
  ]

  extra_ssl_certs = [
    {
      https_listener_index = 0
      certificate_arn      = module.alb_wildcard_cert.acm_certificate_arn
    }
  ]
}


################################################################################
# ECS
################################################################################

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 4.1.2"

  cluster_name = var.ecs_cluster_id

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        # You can set a simple string and ECS will create the CloudWatch log group for you
        # or you can create the resource yourself to better manage retetion, tagging, etc.
        # TODO Determine if the cloud watch group is created. How about permissions to CloudWatch?
        cloud_watch_log_group_name = "/aws/ecs/${var.ecs_cluster_id}"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 1
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }
}

# TODO Add autoscaling policy based on the CPU usage
module "service_api" {
  source = "./ecs-fargate-service"

  vpc_id                 = var.vpc_id
  vpc_cidr_block         = var.vpc_cidr_block
  cluster_id             = module.ecs.cluster_id
  task_image             = var.api_task_image
  cmd                    = var.api_task_cmd
  name                   = var.api_service_name
  port                   = 8000
  cpu                    = var.api_service_cpu
  memory                 = var.api_service_memory
  enable_execute_command = true
  subnets                = var.vpc_private_subnets
  lb_target_group_arn    = module.alb.target_group_arns[0]
  config_bucket_name     = var.api_config_bucket_name
  config_file_path       = var.api_config_file_path

  # It is needed because ALB module can create the target group and it is available as output,
  # but terraform throws an error here, because the target group is not associated with LB yet.
  # I assume it is because the target group is created before LB.
  depends_on = [module.alb]
}
