# main.tf - Main infrastructure configuration
 
# =====================================================
# TERRAFORM CONFIGURATION
# =====================================================
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # We specify version to avoid breaking changes
    }
  }
}
 
# =====================================================
# AWS PROVIDER CONFIGURATION
# =====================================================
provider "aws" {
  region = var.aws_region
  # This tells Terraform to use AWS and which region
}
 
# =====================================================
# RANDOM STRING - Makes bucket name unique
# =====================================================
# Why? S3 bucket names must be GLOBALLY unique across all AWS accounts
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}
 
# =====================================================
# S3 BUCKET - Stores and hosts our website
# =====================================================
resource "aws_s3_bucket" "website_bucket" {
  bucket = "${var.project_name}-${random_string.bucket_suffix.result}"
  # Example name: static-website-abc12345
  # force_destroy allows Terraform to delete bucket even if it has files
  force_destroy = true
 
  tags = {
    Name        = "${var.project_name}-website"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
 
# =====================================================
# S3 BUCKET - Disable Block Public Access
# =====================================================
# Why? By default S3 blocks all public access.
# We need to allow public access so people can view our website
resource "aws_s3_bucket_public_access_block" "website_bucket_public_access" {
  bucket = aws_s3_bucket.website_bucket.id
 
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
 
# =====================================================
# S3 BUCKET - Enable Website Hosting
# =====================================================
# Why? This enables S3 to serve files as a website with a URL
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id
 
  # What file to show when someone visits the root URL
  index_document {
    suffix = "index.html"
  }
 
  # What file to show when there's an error (like 404)
  error_document {
    key = "error.html"
  }
}
 
# =====================================================
# S3 BUCKET POLICY - Allow Public Read Access
# =====================================================
# Why? This policy allows anyone on the internet to READ (view) files
# Without this, the website would show "Access Denied" to visitors
resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
 
  # We must disable public access block BEFORE applying policy
  depends_on = [aws_s3_bucket_public_access_block.website_bucket_public_access]
 
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"          # * means everyone/anyone
        Action    = "s3:GetObject"  # Allow only reading/downloading files
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"  # All files in bucket
      }
    ]
  })
}
 
# =====================================================
# S3 BUCKET - For CodePipeline Artifacts
# =====================================================
# Why? CodePipeline needs a separate S3 bucket to store
# temporary files between pipeline stages (called artifacts)
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket        = "${var.project_name}-pipeline-${random_string.bucket_suffix.result}"
  force_destroy = true
 
  tags = {
    Name      = "${var.project_name}-pipeline-artifacts"
    ManagedBy = "terraform"
  }
}
 
# Block public access for pipeline bucket (it should be private)
resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
 
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
 
# =====================================================
# AWS CODESTARCONNECTIONS - Connect to GitHub
# =====================================================
# Why? This creates a secure connection between AWS and GitHub
# so CodePipeline can automatically detect when you push code


 
# =====================================================
# CODE BUILD PROJECT
# =====================================================
# Why? CodeBuild is where AWS runs our build commands
# It reads buildspec.yml and executes the steps
resource "aws_codebuild_project" "website_build" {
  name          = "${var.project_name}-build"
  description   = "Build project for static website"
  build_timeout = "10"  # Maximum 10 minutes for build
  service_role  = aws_iam_role.codebuild_role.arn  # Permissions for CodeBuild
 
  # Where CodeBuild stores its output files
  artifacts {
    type = "CODEPIPELINE"  # Artifacts managed by CodePipeline
  }
 
  # The build environment (like a temporary computer where build runs)
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"  # Small = cheapest
    image                       = "aws/codebuild/standard:7.0"  # Pre-built environment with common tools
    type                        = "LINUX_CONTAINER"  # Linux operating system
    image_pull_credentials_type = "CODEBUILD"
  }
 
  # Where to find build instructions
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"  # File in our repo with build commands
  }
 
  tags = {
    Name      = "${var.project_name}-build"
    ManagedBy = "terraform"
  }
}
 
# =====================================================
# CODE PIPELINE
# =====================================================
# Why? CodePipeline is the ORCHESTRATOR - it connects
# GitHub → CodeBuild → S3 deployment automatically
resource "aws_codepipeline" "website_pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn  # Permissions for pipeline
 
  # Where pipeline stores temporary files
  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }
 
  # ---- STAGE 1: GET SOURCE CODE ----
  # Why? Pipeline needs to download your code from GitHub first
  

  stage {
  name = "Source"

  action {
    name             = "Source"
    category         = "Source"
    owner            = "AWS"
    provider         = "CodeStarSourceConnection"
    version          = "1"
    output_artifacts = ["source_output"]

    configuration = {
      ConnectionArn    = var.github_connection_arn
      FullRepositoryId = "${var.github_repo_owner}/${var.github_repo_name}"
      BranchName       = var.github_branch
      DetectChanges    = "true"
    }
  }
}


 
  # ---- STAGE 2: BUILD ----
  # Why? This stage runs our buildspec.yml which validates
  # and prepares files for deployment
  stage {
    name = "Build"
 
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]   # Use output from Stage 1
      output_artifacts = ["build_output"]    # Pass output to Stage 3
      version          = "1"
 
      configuration = {
        ProjectName = aws_codebuild_project.website_build.name
      }
    }
  }
 
  # ---- STAGE 3: DEPLOY ----
  # Why? This stage takes the built files and copies them to
  # our website S3 bucket so users can access them
  stage {
    name = "Deploy"
 
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["build_output"]  # Use output from Stage 2
      version         = "1"
 
      configuration = {
        BucketName = aws_s3_bucket.website_bucket.bucket
        Extract    = "true"  # Extract zip file into the bucket
      }
    }
  }
}
