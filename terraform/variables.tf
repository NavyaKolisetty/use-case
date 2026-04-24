variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "static-website"
}

variable "github_repo_owner" {
  description = "GitHub username"
  type        = string
  default     = "NavyaKolisetty"
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
  default     = "use-case"
}

variable "github_branch" {
  description = "GitHub branch"
  type        = string
  default     = "main"
}

variable "github_connection_arn" {
  description = "Existing GitHub connection ARN"
  type        = string
  default     = "arn:aws:codeconnections:ap-south-1:239359658737:connection/2ac88a31-9565-412b-9ab9-a2bcde9f4a7d"
}

