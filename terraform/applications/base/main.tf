data "aws_caller_identity" "current" {}


################################################################################
# ECR for API image
################################################################################

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = var.repository_name

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
