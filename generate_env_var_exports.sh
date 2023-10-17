#!/bin/bash

set -e

CURRENT_DIR=$(realpath $(dirname $0))
TERRAFORM_DIR="${CURRENT_DIR}/terraform"


# Authentication
echo "export TF_VAR_AWS_SECRET_KEY=1oWn3IPvyD5nFo4Y7GY4gWpEmWlAZ+Q9pyCw0a7E"
echo "export TF_VAR_AWS_ACCESS_KEY=AKIASGXWZ2W5D6SWP6VM"

# Resource Location
echo "export TF_VAR_AWS_REGION=us-east-2"
echo "export TF_VAR_AWS_ACCOUNT_ID=151915189690"

# CodeCommit
echo "export TF_VAR_AWS_REPOSITORY_NAME=tf-test"
echo "export TF_VAR_BUILDSPEC_PATH=buildspec.yml"


