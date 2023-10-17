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

        # ===============================================
        # Import the CodeCommit related resources
        # ===============================================
	terraform -chdir="${WORKING_DIR}" import aws_codecommit_repository.aws-repo "${TF_VAR_AWS_REPOSITORY_NAME}" || true


        # ===============================================
        # Import the CloudWatch related resources
        # ===============================================

	terraform -chdir="${WORKING_DIR}" import aws_cloudwatch_event_rule.events-rule "codecommit-${TF_VAR_AWS_REPOSITORY_NAME}" || true

        RULENAME="codecommit-${TF_VAR_AWS_REPOSITORY_NAME}"
        TARGETID=$(aws events list-targets-by-rule --rule codecommit-tf-test | jq --raw-output ".Targets[0].Id" || true)
        if [ ! -z "${TARGETID}" ]; then
                RESOURCE_ID="${RULENAME}/${TARGETID}"
	        terraform -chdir="${WORKING_DIR}" import aws_cloudwatch_event_target.event-target "${RESOURCE_ID}" || true
        fi

        # ===============================================
        # Import the Lambda related resources
        # ===============================================
        terraform -chdir="${WORKING_DIR}" import aws_iam_role.terraform-function-role terraform-function-role || true

        ROLE_NAME="terraform-function-role"
        POLICY_ARN="arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        RESOURCE_ID="${ROLE_NAME}/${POLICY_ARN}"

        terraform -chdir="${WORKING_DIR}" import aws_iam_role_policy_attachment.terraform-lambda-policy "${RESOURCE_ID}" || true

        IAM_POLICY_NAME=lambda-start-codebuild
        IAM_POLICY_ARN=$(aws iam list-policies | jq -r ".Policies[] | select(.PolicyName==\"${IAM_POLICY_NAME}\")" | jq -r '.Arn')        
        RESOURCE_ID="${IAM_POLICY_ARN}"
        if [ ! -z "${IAM_POLICY_ARN}" ]; then
                terraform -chdir="${WORKING_DIR}" import aws_iam_policy.lambda-start-codebuild "${RESOURCE_ID}" || true
        fi

        IAM_ROLE_NAME="terraform-function-role"
        RESOURCE_ID="${IAM_ROLE_NAME}/${IAM_POLICY_ARN}"
        if [ ! -z "${IAM_POLICY_ARN}" ]; then
                terraform -chdir="${WORKING_DIR}" import aws_iam_role_policy_attachment.lambda-start-codebuild "${RESOURCE_ID}" || true
        fi

        terraform -chdir="${WORKING_DIR}" import aws_lambda_function.lambda-function "${TF_VAR_AWS_REPOSITORY_NAME}-codebuild-trigger" || true

        FUNCTION_NAME="${TF_VAR_AWS_REPOSITORY_NAME}-codebuild-trigger"
        STATEMENT_ID="1"
        RESOURCE_ID="${FUNCTION_NAME}/${STATEMENT_ID}"
        terraform -chdir="${WORKING_DIR}" import aws_lambda_permission.lambda-permission "${RESOURCE_ID}" || true

        # ===============================================
        # Import the CodeBuild related resources
        # ===============================================
        terraform -chdir="${WORKING_DIR}" import aws_iam_role.codebuild "codebuild-${TF_VAR_AWS_REPOSITORY_NAME}" || true

        IAM_POLICY_NAME="${TF_VAR_AWS_REPOSITORY_NAME}"
        IAM_POLICY_ARN=$(aws iam list-policies \
                | jq -r ".Policies[] | select(.PolicyName==\"${IAM_POLICY_NAME}\")" \
                | jq -r '.Arn')
        RESOURCE_ID=${IAM_POLICY_ARN}
        terraform -chdir="${WORKING_DIR}" import aws_iam_policy.cloudwatch-create-logs "${RESOURCE_ID}" || true

        ## ^^ Errors but idnoring for now

        ROLE_NAME="codebuild-${TF_VAR_AWS_REPOSITORY_NAME}"
        IAM_POLICY_NAME="${TF_VAR_AWS_REPOSITORY_NAME}"
        IAM_POLICY_ARN=$(aws iam list-policies \
                | jq -r ".Policies[] | select(.PolicyName==\"${IAM_POLICY_NAME}\")" \
                | jq -r '.Arn')        
        RESOURCE_ID="${ROLE_NAME}/${IAM_POLICY_ARN}"
        if [ ! -z "${IAM_POLICY_ARN}" ]; then
                terraform -chdir="${WORKING_DIR}" import aws_iam_role_policy_attachment.cloudwatch-create-logs "${RESOURCE_ID}" || true
        fi

        IAM_POLICY_NAME=codebuild-access-codecommit
        IAM_POLICY_ARN=$(aws iam list-policies | jq -r ".Policies[] | select(.PolicyName==\"${IAM_POLICY_NAME}\")" | jq -r '.Arn')        
        RESOURCE_ID="${IAM_POLICY_ARN}"
        if [ ! -z "${IAM_POLICY_ARN}" ]; then
                terraform -chdir="${WORKING_DIR}" import aws_iam_policy.codebuild-access-codecommit "${RESOURCE_ID}" || true
        fi

        RESOURCE_ID="${ROLE_NAME}/${IAM_POLICY_ARN}"
        if [ ! -z "${IAM_POLICY_ARN}" ]; then
                terraform -chdir="${WORKING_DIR}" import aws_iam_role_policy_attachment.codebuild-access-codecommit "${RESOURCE_ID}" || true
        fi

        terraform -chdir="${WORKING_DIR}" import aws_codebuild_project.codebuild-project "${TF_VAR_AWS_REPOSITORY_NAME}" || true
