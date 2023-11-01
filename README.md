# Overview

This directory contains configurations and utilities for setting up AWS infrastructure required to perform Continuous Integration (CI) for a multi-branch branching strategy (Like TBD, gitflow, oneflow, etc.).

Out of the box, the AWS console does not provide an effective means for setting up this infrastructure. The basic problem is that the out-of-the-box configurations required branches to exist before the CI automation can be setup. With this solution, we do not need to know the branch names ahead of time.

# How It Works
The basic process is to define some BASH environment variables and then use terraform to provision the declared AWS infrastructure.

## BASH Environment Variables
- `TF_VAR_AWS_SECRET_KEY` - The secret key terraform will use to authenticate with AWS. 
- `TF_VAR_AWS_ACCESS_KEY` - The access key terraform will use to authenticate with AWS.

**Note:** The User associated with this Key must have the permissions to create and destroy all the infrastructure associated with this project. Additionally, because the User is associated with an AWS Account, these Keys also dictate which Account will host the infrastructure.

- `TF_VAR_AWS_ACCOUNT' - The AWS Account ID in which resources will be provisioned.
- `TF_VAR_AWS_REGION` - The AWS Region in which the resources will be provisioned.
- `TF_VAR_AWS_REPOSITORY` - The name of the CodeCommit repository to create. All the other infrastructure will be prefixed with this name in some way.

**Note:** If this repo already exists, terraform will just build the components around it.

- `TF_VAR_BUILDSPEC_PATH` - The absolute file path of where the buildspec file will be found within the new repo being created. The buildspec file is what defines the execution steps of the CodeBuild Pipeline.

- `TF_VAR_MAINLINE_BRANCHES` - A json array of fully qualified branch names which will be protected
- `TF_VAR_MAINLINE_APPROVALS` - The number of approvals from the approval group or approvers list
- `TF_VAR_MAINLINE_APPROVERS` - The IAM User names, User ARNs, or IAM Groups attached to the policy
- `TF_VAR_RELEASE_BRANCHES`  - A json array of fully qualified branch names which will be protected
- `TF_VAR_RELEASE_APPROVALS` - The number of approvals from the approval group or approvers list
- `TF_VAR_RELEASE_APPROVERS` - The IAM User names, User ARNs, or IAM Groups attached to the policy

## Setting The BASH Environment Variables
The easiest way is to modify the [generate_env_var_exports.sh](bash/generate_env_var_exports.sh) file by overriding the default values for these BASH variables. Then running the following command:

```
eval $(bash bash/generate_env_var_exports.sh)
```

## Running Terraform
This repository contains a helper script to run terraform and provision the desired infrastructure.

```
bash bash/configure_repository.sh
```

Additionally it can configure the branch protections for the mainline and release branches.

```
bash bash/implement_branching_strategy.sh
```

## Rebuilding Terraform State
In the event that the state file is lost or deleted, we can rebuild it via the following:

```
bash bash/rebuild_base_infrastructure_state.sh
bash bash/rebuild_branching_strategy_state.sh
```

## Architecture

This solution relies on a Lambda Function which sits between CodeCommit and CodeBuild. The function will observe VCS events and then trigger CodeBuild if appropriate.

<center><img src=./images/Architecture.png></center>

The Lambda Function will pass the commit hash and branch name to the CodeBuild pipeline via BASH Environment Variables. The codebuild pipeline can then uses these variables to determine how to handle the VCS event.

# Requirements
In order to provision the resources, the following are required:
- BASH >= 4.0
- Terraform >= 1.5

In order to rebuild the statefile using the [rebuild_terraform_state.sh](./bash/rebuild_terraform_state.sh) the following additional packages are required:
- aws cli (can be installed with awscli pip package)
- jq
