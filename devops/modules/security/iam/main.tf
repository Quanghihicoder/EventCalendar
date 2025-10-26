# Backend  ECS EC2 instance role
resource "aws_iam_role" "backend_instance_role" {
  name = "${var.project_name}-backend-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement : [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "backend_instance_profile" {
  name = "${var.project_name}-backend-instance-profile"
  role = aws_iam_role.backend_instance_role.name
}

resource "aws_iam_role_policy_attachment" "backend_instance_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.backend_instance_role.name
}

resource "aws_iam_role_policy_attachment" "backend_instance_cloudwatch_policy" {
  role       = aws_iam_role.backend_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Backend task exec role
resource "aws_iam_role" "backend_task_exec_role" {
  name = "${var.project_name}-backend-task-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement : [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# resource "aws_iam_policy" "backend_task_permissions" {
#   name = "${var.project_name}-backend-task-policy"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "backend_task_attach_policy" {
#   role       = aws_iam_role.backend_task_exec_role.name
#   policy_arn = aws_iam_policy.backend_task_permissions.arn
# }
