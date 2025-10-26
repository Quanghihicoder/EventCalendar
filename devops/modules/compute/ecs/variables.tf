variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_region" {
  type = string
}

variable "instance_type" {
  description = "The instance type of the EC2 instance running the ECS container"
  type        = string
  default     = "t3.micro"
}

variable "public_subnet_a_id" {
  description = "ID of the public subnet A"
  type        = string
}


variable "backend_sg_id" {
  description = "ID of the ECS security group"
  type        = string
}

variable "backend_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  type        = string
}

variable "backend_task_exec_role_arn" {
  description = "ARN of the ECS take execution"
  type        = string
}



variable "backend_image_url" {
  description = "ECS image URL"
  type        = string
}

variable "alb_target_group_arn" {
  description = "aws_lb_target_group.tilelens_tg.arn"
  type        = string
}

