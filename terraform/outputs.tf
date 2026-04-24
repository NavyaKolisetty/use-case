output "website_url" {
  description = "Static website URL"
  value       = "http://${aws_s3_bucket_website_configuration.website_config.website_endpoint}"
}

output "website_bucket_name" {
  description = "Website bucket name"
  value       = aws_s3_bucket.website_bucket.bucket
}

output "pipeline_bucket_name" {
  description = "Pipeline artifact bucket name"
  value       = aws_s3_bucket.codepipeline_bucket.bucket
}

output "codepipeline_name" {
  description = "CodePipeline name"
  value       = aws_codepipeline.website_pipeline.name
}

output "github_connection_arn" {
  description = "GitHub connection ARN"
  value       = var.github_connection_arn
}

