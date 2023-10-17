# ==========================================================
# Define IAM Policy For CodeBuild Service To Assume Role
# ==========================================================
# The Services in AWS by default, have a limited set of permissions. We can enable those
# Services to perform additional Actions by allowing them to Assume Roles. By Assuming a Role,
# the assumer is temporarily granted the Permissions associated with that Role. In order to
# give the Service the ability to Assume a Role, we must define an IAM Policy, Attach it to a Role,
# and then configure the Service to use the Role.


# Data sources in Terraform are used to get information about resources external to 
# Terraform, and use them to set up your Terraform resources.
#
#   https://spacelift.io/blog/terraform-data-sources-how-they-are-utilised
#
# In the case of the aws_iam_policy_document data source, we are generating a temporary object
# which represents an IAM Policy. This temporary object can be used with other terraform objects 
# that expect policy documents such as aws_iam_policy.
#
# Note: The aws_iam_policy_document can also load IAM Policies from json files
# 

data "aws_iam_policy_document" "codebuild-assume-role" {
  statement {
    actions       = ["sts:AssumeRole"]
    effect        = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

# ===========================================================
# Define IAM Role To Attach Policies For CodeBuild Service
# ===========================================================
# We will define and attach policies to this role

resource "aws_iam_role" "codebuild" {
  name               = "codebuild-${var.AWS_REPOSITORY_NAME}"
  assume_role_policy = data.aws_iam_policy_document.codebuild-assume-role.json
}

# =========================================================
# Define IAM Policy To Allow Creation Of Cloudwatch Logs
# =========================================================
# By default, the CodeBuild service will not be able to run because it cannot create
# the various log groups in cloudwatch. Without this we will see the following error:
#
#      ... not authorized to perform: logs:CreateLogStream on resource: ...
#      because no identity-based policy allows the logs:CreateLogStream action
# 
# https://stackoverflow.com/questions/74886950/pipleline-wont-build-and-shows-access-denied-error-even-after-changing-policies
#

data "aws_iam_policy_document" "cloudwatch-create-logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch-create-logs" {
  name        = "${var.AWS_REPOSITORY_NAME}"
  path        = "/"
  description = "IAM Policy to allow creation of cloudwatch logs"
  policy      = data.aws_iam_policy_document.cloudwatch-create-logs.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch-create-logs" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.cloudwatch-create-logs.arn
}

# =========================================================
# Define IAM Policy To Allow Accessing CodeCommit Repository
# =========================================================
# https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-permissions-reference.html


data "aws_iam_policy_document" "codebuild-access-codecommit" {
  statement {
    effect = "Allow"

    actions = [
      "codecommit:GitPull",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "codebuild-access-codecommit" {
  name        = "codebuild-access-codecommit"
  description = "IAM Policy to allow CodeBuild to access CodeCommit repositories."
  policy      = data.aws_iam_policy_document.codebuild-access-codecommit.json
}

resource "aws_iam_role_policy_attachment" "codebuild-access-codecommit" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild-access-codecommit.arn
}

# ==================================================
# Define The CodeBuild Pipeline
# ==================================================
#
# https://docs.aws.amazon.com/codebuild/latest/APIReference/API_ProjectSource.html

resource "aws_codebuild_project" "codebuild-project" {
  name          = "${var.AWS_REPOSITORY_NAME}"
  description   = "A Pipeline to build the ${var.AWS_REPOSITORY_NAME} repository."
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${aws_codecommit_repository.aws-repo.repository_name}"
    }
  }

  source {
    type            = "CODECOMMIT"
    buildspec       = "${var.BUILDSPEC_PATH}"
    location        = aws_codecommit_repository.aws-repo.clone_url_http
    git_clone_depth = 0

    git_submodules_config {
      fetch_submodules = true
    }
  }
}
