#!/bin/bash

set -e

CURRENT_DIR=$(realpath $(dirname $0))
TERRAFORM_DIR="${CURRENT_DIR}/../terraform"


# Authentication
echo "export TF_VAR_AWS_SECRET_KEY=I5ck/zEupprAaF6l8moiwr+iuiKX+uGdCfYM0IDR"
echo "export TF_VAR_AWS_ACCESS_KEY=AKIASGXWZ2W5DYI75JWU"

# Resource Location
echo "export TF_VAR_AWS_ACCOUNT=151915189690"
echo "export TF_VAR_AWS_REGION=us-east-2"

# CodeCommit
echo "export TF_VAR_AWS_REPOSITORY_NAME=tf-test"
echo "export TF_VAR_BUILDSPEC_PATH=buildspec.yml"

# Branching Strategy (put json array here)
echo "export TF_VAR_MAINLINE_BRANCHES='[\"refs/heads/master\"]'"
echo "export TF_VAR_MAINLINE_APPROVALS=2"
echo "export TF_VAR_MAINLINE_APPROVERS='[\"arn:aws:iam::151915189690:user/taylor\"]'" # User name, arn, or role

echo "export TF_VAR_RELEASE_BRANCHES='[\"refs/heads/release/*\"]'"
echo "export TF_VAR_RELEASE_APPROVALS=2"
echo "export TF_VAR_RELEASE_APPROVERS='[\"arn:aws:iam::151915189690:user/taylor\"]'" # User name, arn, or role


