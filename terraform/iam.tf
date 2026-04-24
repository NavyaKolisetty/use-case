# iam.tf - All IAM roles and permissions
 
# =====================================================
# IAM ROLE FOR CODEPIPELINE
# =====================================================
# Why? CodePipeline needs permissions to:
# - Access GitHub via CodeStar connection
# - Trigger CodeBuild
# - Read/Write to S3 buckets
 
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-role"
 
  # Trust policy: Who can USE this role?
  # Only CodePipeline service can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
 
  tags = {
    ManagedBy = "terraform"
  }
}
 
# What can CodePipeline DO with this role?
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id
 
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permission to read/write to artifact S3 bucket
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_bucket.arn,
          "${aws_s3_bucket.codepipeline_bucket.arn}/*",
          aws_s3_bucket.website_bucket.arn,
          "${aws_s3_bucket.website_bucket.arn}/*"
        ]
      },
      # Permission to use GitHub connection
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = aws_codestarconnections_connection.github_connection.arn
      },
      # Permission to trigger and monitor CodeBuild
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      }
    ]
  })
}
 
# =====================================================
# IAM ROLE FOR CODEBUILD
# =====================================================
# Why? CodeBuild needs permissions to:
# - Write logs to CloudWatch (so we can see build output)
# - Read/Write to S3 buckets
 
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-codebuild-role"
 
  # Only CodeBuild service can use this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
 
  tags = {
    ManagedBy = "terraform"
  }
}
 
# What can CodeBuild DO?
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.project_name}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id
 
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permission to create and write logs
      # Why? So we can see what happened during build
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      # Permission to access S3 buckets
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_bucket.arn,
          "${aws_s3_bucket.codepipeline_bucket.arn}/*",
          aws_s3_bucket.website_bucket.arn,
          "${aws_s3_bucket.website_bucket.arn}/*"
        ]
      }
    ]
  })
}
