#! /bin/bash

# Terraform manages state in a state file
# In the case that the state file gets out of sync with the environment, we will need to do a refresh
# Currently this is a manual process and this script will do that work

set -e
set -x

        CURRENT_DIR=$(dirname $(realpath $0))
        WORKING_DIR=$1

        # The working dir is expected to be a path relative to the repo root or and absolute path.
        # We will automatically convert a relative path to an absolut path

        if [ -z "${WORKING_DIR}" ]; then
                echo "Working directory was not provided"
                exit 1
        fi
        if [ ! -d "${WORKING_DIR}" ]; then
                ROOT_DIR=$(realpath $CURRENT_DIR/../)
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
        # Import the mainline branch protections
        # ===============================================
	terraform -chdir="${WORKING_DIR}" import \
		aws_codecommit_approval_rule_template.approvalrule-mainline \
		"${TF_VAR_AWS_REPOSITORY_NAME}-approvalrule-mainline"		

        terraform -chdir="${WORKING_DIR}" import \
		aws_codecommit_approval_rule_template_association.approval-rule-association-mainline \
                "${TF_VAR_AWS_REPOSITORY_NAME}-approvalrule-mainline,${TF_VAR_AWS_REPOSITORY_NAME}"


        IAM_POLICY_NAME="${TF_VAR_AWS_REPOSITORY_NAME}-mainline"
        IAM_POLICY_ARN=$(aws iam list-policies | jq -r ".Policies[] \
		| select(.PolicyName==\"${IAM_POLICY_NAME}\")" | jq -r '.Arn')
        RESOURCE_ID="${IAM_POLICY_ARN}"
        if [ ! -z "${IAM_POLICY_ARN}" ]; then
                terraform -chdir="${WORKING_DIR}" import \
		aws_iam_policy.branch-protection-policy-mainline "${RESOURCE_ID}" || true
        fi

	IAM_USER_NAMES=$(aws iam list-users | jq -r ".Users[].UserName")
	for IAM_USER_NAME in $(echo $IAM_USER_NAMES); do
	        RESOURCE_ID="${IAM_USER_NAME}/${IAM_POLICY_ARN}"
	        if [ ! -z "${IAM_POLICY_ARN}" ]; then
	                terraform -chdir="${WORKING_DIR}" import \
				aws_iam_user_policy_attachment.policy-attachment-mainline\[\"$IAM_USER_NAME\"\] \
				"${RESOURCE_ID}" || true
	        fi
	done	

        # ===============================================
        # Import the release branch protections
        # ===============================================

        terraform -chdir="${WORKING_DIR}" import \
                aws_codecommit_approval_rule_template.approvalrule-release \
                "${TF_VAR_AWS_REPOSITORY_NAME}-approvalrule-release"

        terraform -chdir="${WORKING_DIR}" import \
                aws_codecommit_approval_rule_template_association.approval-rule-association-release \
                "${TF_VAR_AWS_REPOSITORY_NAME}-approvalrule-release,${TF_VAR_AWS_REPOSITORY_NAME}"


        IAM_POLICY_NAME="${TF_VAR_AWS_REPOSITORY_NAME}-release"
        IAM_POLICY_ARN=$(aws iam list-policies | jq -r ".Policies[] \
                | select(.PolicyName==\"${IAM_POLICY_NAME}\")" | jq -r '.Arn')
        RESOURCE_ID="${IAM_POLICY_ARN}"
        if [ ! -z "${IAM_POLICY_ARN}" ]; then
                terraform -chdir="${WORKING_DIR}" import \
                aws_iam_policy.branch-protection-policy-release "${RESOURCE_ID}" || true
        fi

        IAM_USER_NAMES=$(aws iam list-users | jq -r ".Users[].UserName")
        for IAM_USER_NAME in $(echo $IAM_USER_NAMES); do
                RESOURCE_ID="${IAM_USER_NAME}/${IAM_POLICY_ARN}"
                if [ ! -z "${IAM_POLICY_ARN}" ]; then
                        terraform -chdir="${WORKING_DIR}" import \
                                aws_iam_user_policy_attachment.policy-attachment-release\[\"$IAM_USER_NAME\"\] \
                                "${RESOURCE_ID}" || true
                fi
        done

