data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

resource "aws_ecs_cluster" "backend" {
  name = "${var.project_name}-backend"
}

resource "aws_instance" "backend" {
  ami                         = data.aws_ami.ecs_ami.id
  instance_type               = var.instance_type # it is cheaper to use t3.small running 4 tasks than t3.micro but can only run 1 task which will need to add more ec2 instances
  subnet_id                   = var.public_subnet_a_id
  iam_instance_profile        = var.backend_instance_profile_name
  security_groups             = [var.backend_sg_id]
  associate_public_ip_address = true

  user_data = <<EOF
  #!/bin/bash
  echo ECS_CLUSTER=${aws_ecs_cluster.backend.name} >> /etc/ecs/ecs.config
  echo "ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"awslogs\"]" >> /etc/ecs/ecs.config
  EOF

  tags = {
    Name = "${var.project_name}-backend-instance"
  }
}

resource "aws_eip" "backend_eip" {
  instance = aws_instance.backend.id
  domain   = "vpc"
}

resource "aws_ecs_task_definition" "backend_app_task" {
  family                   = "${var.project_name}-backend"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = "256"
  memory                   = "512"
  task_role_arn            = var.backend_task_exec_role_arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-backend",
      image     = var.backend_image_url,
      essential = true,
      portMappings = [{
        containerPort = 9000
        hostPort      = 9000
      }],
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-service"
  cluster         = aws_ecs_cluster.backend.id
  task_definition = aws_ecs_task_definition.backend_app_task.arn
  desired_count   = 1
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "${var.project_name}-backend"
    container_port   = 9000
  }
}
