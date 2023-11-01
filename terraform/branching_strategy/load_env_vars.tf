# https://support.hashicorp.com/hc/en-us/articles/4547786359571-Reading-and-using-environment-variables-in-Terraform-runs


# Vars prefixed with TF_VAR_ can be loaded below

variable "AWS_SECRET_KEY" {}
variable "AWS_ACCESS_KEY" {}

variable "AWS_ACCOUNT" {}
variable "AWS_REGION" {}

variable "AWS_REPOSITORY_NAME" {}
variable "BUILDSPEC_PATH" {}

variable "MAINLINE_BRANCHES" {}
variable "MAINLINE_APPROVALS" {}
variable "MAINLINE_APPROVERS" {}

variable "RELEASE_BRANCHES" {}
variable "RELEASE_APPROVALS" {}
variable "RELEASE_APPROVERS" {}

locals {
 MAINLINE_BRANCHES_ARRAY  = jsondecode("${var.MAINLINE_BRANCHES}")
 MAINLINE_APPROVERS_ARRAY = jsondecode("${var.MAINLINE_APPROVERS}")
 RELEASE_BRANCHES_ARRAY   = jsondecode("${var.RELEASE_BRANCHES}")
 RELEASE_APPROVERS_ARRAY  = jsondecode("${var.RELEASE_APPROVERS}")
 REPO_ARN                 = "arn:aws:codecommit:${var.AWS_REGION}:${var.AWS_ACCOUNT}:${var.AWS_REPOSITORY_NAME}"
}

data "aws_iam_users" "all-users" {}

