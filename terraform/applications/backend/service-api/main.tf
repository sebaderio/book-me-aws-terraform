data "aws_region" "current" {}

locals {
  cw_log_group = "/aws/ecs/${var.name}"
  container_definition = [{
    name        = var.name
    image       = var.task_image
    cpu         = var.cpu
    memory      = var.memory
    networkMode = "awsvpc"
    portMappings = [
      {
        protocol      = "tcp"
        containerPort = var.port
        hostPort      = var.port
      }
    ]
    logConfiguration = {
      logdriver = "awslogs"
      options = {
        "awslogs-group"         = local.cw_log_group
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "stdout"
      }
    }
  }]
}

resource "aws_security_group" "fargate_task" {
  name   = "${var.name}-fargate-task"
  vpc_id = var.vpc_id
  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "fargate_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "execution" {
  name   = "fargate_execution_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetAuthorizationToken",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "task" {
  name   = "fargate_task_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "servicediscovery:ListServices",
            "servicediscovery:ListInstances"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "execution" {
  name               = "${var.name}-fargate-execution-role"
  assume_role_policy = data.aws_iam_policy_document.fargate_role_policy.json
}

resource "aws_iam_role" "task" {
  name               = "${var.name}-fargate-task-role"
  assume_role_policy = data.aws_iam_policy_document.fargate_role_policy.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.execution.arn
}

resource "aws_iam_role_policy_attachment" "task" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task.arn
}

resource "aws_cloudwatch_log_group" "app" {
  name = local.cw_log_group
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.name
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  requires_compatibilities = ["FARGATE"]
  container_definitions    = jsonencode(local.container_definition)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
}

resource "aws_ecs_service" "app" {
  name            = var.name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  network_configuration {
    security_groups = [aws_security_group.fargate_task.id]
    subnets         = var.subnets
  }
}
