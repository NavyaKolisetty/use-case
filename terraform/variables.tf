variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
  # We use us-east-1 because it supports all AWS services we need
}
 
variable "project_name" {
  description = "Name of the project - used to name all resources"
  type        = string
  default     = "static-website"
  # This name will appear in S3 bucket name, CodePipeline name, etc.
}
 
variable "github_repo_owner" {
  description = "Your GitHub username"
  type        = string
  default     = "YOUR_GITHUB_USERNAME"
  # IMPORTANT: Replace with your actual GitHub username
}
 
variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
  default     = "static-website-cicd"
  # This should match the repo name you created on GitHub
}
 
variable "github_branch" {
  description = "GitHub branch to watch for changes"
  type        = string
  default     = "main"
  # Pipeline will trigger when you push to this branch
}
