
# outputs.tf - Values to display after terraform apply
 
output "website_url" {
  description = "URL of the static website - Open this in browser"
  value       = "http://${aws_s3_bucket_website_configuration.website_config.website_endpoint}"
}
 
output "website_bucket_name" {
  description = "Name of the S3 bucket hosting the website"
  value       = aws_s3_bucket.website_bucket.bucket
}
 
output "pipeline_bucket_name" {
  description = "Name of S3 bucket used by CodePipeline for artifacts"
  value       = aws_s3_bucket.codepipeline_bucket.bucket
}
 
output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.website_pipeline.name
}
 
output "github_connection_arn" {
  description = "ARN of GitHub connection - You need to authorize this manually"
  value       = aws_codestarconnections_connection.github_connection.arn
}
 
output "aws_console_pipeline_url" {
  description = "Direct link to view pipeline in AWS Console"
  value       = "https://${var.aws_region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipelin…
}

