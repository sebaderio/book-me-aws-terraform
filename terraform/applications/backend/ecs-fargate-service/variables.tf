variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "cluster_id" {
  type        = string
  description = "The ECS cluster ID"
}

variable "name" {
  type        = string
  description = "The name of the ECS service to create."
}

variable "task_image" {
  type        = string
  description = "Name of the docker image publicly available in the DockerHub."
}

variable "cmd" {
  type        = list(string)
  description = "Command to run in the task."
}

variable "port" {
  type        = number
  description = "Port number on which the ECS service answers requests."
}

variable "cpu" {
  type        = number
  description = "CPU allocation for the ECS service."
}

variable "memory" {
  type        = number
  description = "CPU allocation for the ECS service."
}

variable "desired_count" {
  type        = number
  default     = 1
  description = "Desired number of instances of the task definition."
}

variable "enable_execute_command" {
  type        = bool
  default     = true
  description = "Allow to run commands invoked outside of the container using ECS exec."
}

variable "subnets" {
  type        = list(string)
  description = "Subnets in wich the ECS service can be created."
}

variable "lb_target_group_arn" {
  type        = string
  description = "ARN of the Load Balancer target group to associate with the ECS service."
}

variable "config_bucket_name" {
  type        = string
  description = "Name of the s3 bucket where file with service settings and secrets resides."
}

variable "config_file_path" {
  type        = string
  description = "Path to the file with settings and secrets in the config s3 bucket."
  # TODO add validation -> min length 5 (/.env), starts with "/", ends with ".env"
}
