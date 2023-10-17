#!/bin/bash

set -e
set -x

CURRENT_DIR=$(realpath $(dirname $0))
AWS_DIR=$(dirname $CURRENT_DIR)
TERRAFORM_DIR="$AWS_DIR/terraform"


cd $TERRAFORM_DIR
terraform init
terraform plan
terraform apply -auto-approve
