#!/bin/bash

set -e
set -x

CURRENT_DIR=$(realpath $(dirname $0))
AWS_DIR=$(dirname $CURRENT_DIR)
TERRAFORM_DIR="${AWS_DIR}/terraform"
BRANCHING_STRATEGY_DIR="${TERRAFORM_DIR}/branching_strategy"

cd $BRANCHING_STRATEGY_DIR
terraform init
terraform plan
terraform apply -auto-approve
