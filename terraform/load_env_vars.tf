# https://support.hashicorp.com/hc/en-us/articles/4547786359571-Reading-and-using-environment-variables-in-Terraform-runs


# Vars prefixed with TF_VAR_ can be loaded below

variable "AWS_SECRET_KEY" {}
variable "AWS_ACCESS_KEY" {}

variable "AWS_REGION" {}
variable "AWS_ACCOUNT_ID" {}

variable "AWS_REPOSITORY_NAME" {}
variable "BUILDSPEC_PATH" {}
