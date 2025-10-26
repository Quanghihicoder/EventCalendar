output "backend_instance_profile_name" {
  value = aws_iam_instance_profile.backend_instance_profile.name
}

output "backend_task_exec_role_arn" {
  value = aws_iam_role.backend_task_exec_role.arn
}
