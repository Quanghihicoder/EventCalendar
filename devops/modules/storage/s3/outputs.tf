output "frontend_bucket_arn" {
  value = aws_s3_bucket.app_buckets["frontend"].arn
}

output "frontend_bucket" {
  value = aws_s3_bucket.app_buckets["frontend"].bucket
}


output "app_bucket_regional_domain_names" {
  value = { for k, v in aws_s3_bucket.app_buckets : k => v.bucket_regional_domain_name }
}
