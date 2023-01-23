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


# ################################################################################
# # S3 bucket and DynamoDB table to store state remotely
# ################################################################################
