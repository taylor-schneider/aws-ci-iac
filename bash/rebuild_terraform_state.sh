#! /bin/bash

# Terraform manages state in a state file
# In the case that the state file gets out of sync with the environment, we will need to do a refresh
# Currently this is a manual process and this script will do that work

set -e
set -x

        CURRENT_DIR=$(dirname $0)
        WORKING_DIR=$1

        # The working dir is expected to be a path relative to the repo root or and absolute path.
        # We will automatically convert a relative path to an absolut path

        if [ -z "${WORKING_DIR}" ]; then
                echo "Working directory was not provided"
                exit 1
        fi
        if [ ! -d "${WORKING_DIR}" ]; then
                ROOT_DIR=$(realpath $CURRENT_DIR/../../../../../)
                WORKING_DIR="${ROOT_DIR}/${WORKING_DIR}"
                if [ ! -d "${WORKING_DIR}" ]; then
                        echo "The working directory does not exist"
                        exit 1
                fi
        fi
	
# Delete the terraform state

	rm -f "${WORKING_DIR}/terraform.tfstate"

# Import the resources 

	terraform -chdir="${WORKING_DIR}" init

        # Import the CodeCommit related resources
	terraform -chdir="${WORKING_DIR}" import aws_codecommit_repository.aws-repo "${var.AWS_REPOSITORY_NAME}" || true
	terraform -chdir="${WORKING_DIR}" import aws_cloudwatch_event_rule.events-rule "codecommit-${var.AWS_REPOSITORY_NAME}" || true
	terraform -chdir="${WORKING_DIR}" import aws_cloudwatch_event_target.event-target foobar || true

        # Lambda Related resources
        terraform -chdir="${WORKING_DIR}" import aws_iam_role.terraform_function_role terraform_function_role || true



terraform -chdir="${WORKING_DIR}" import  || true