#----------------------------------------------------------------------#
# Lambda for Stack Creation
#----------------------------------------------------------------------#
# 
# https://aws.amazon.com/blogs/devops/multi-branch-codepipeline-strategy-with-event-driven-architecture/
# 
# Note: The link above's lambda does not work. The API must have changed. I got this working with trial and error.

import boto3
import json

def lambda_handler(event, context):
    
    print(json.dumps(event, indent=4, sort_keys=True, default=str))
    
    # Ignore events not from code commit
    event_source = event["Records"][0]["eventSource"]
    if event_source != "aws:codecommit":
        print(f"Ignoring event from: {Event_source}")
        return
    
    # Determine which branch is affected
    branch_name = event["Records"][0]["codecommit"]["references"][0]["ref"].replace("refs/heads/", "")
    print(f"Processing event for branch: {branch_name}")
    
    # Determine if the branch was added, deleted, or just updated
    created = True if "created" in event["Records"][0]["codecommit"]["references"][0] else False
    deleted = True if "deleted" in event["Records"][0]["codecommit"]["references"][0] else False
    updated = not created and not deleted
    
    # Process the event
    if created:
        print("New branch created. Applying CloudFormation Template.")
    elif deleted:
        print("Branch deleted. Applying CloudFormation Template.")
    else:
        print("Branch updated. Triggering CodeBuild.")
    
    commit_hash = event["Records"][0]["codecommit"]["references"][0]["commit"]
    repo_name = event["Records"][0]["eventSourceARN"].split(":")[-1]


    # Invoking CodeBuild
    #
    #     https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/codebuild/client/start_build.html
    #
    
    client = boto3.client('codebuild')
    codebuild_project_name = "tf-test"
    build_params = {
        "projectName": codebuild_project_name,
        "sourceVersion": branch_name,
        "environmentVariablesOverride": [{
            'name': 'COMMIT_HASH',
            'value': commit_hash,
            'type': 'PLAINTEXT'
        },
        {
            'name': 'BRANCH_NAME',
            'value': branch_name,
            'type': 'PLAINTEXT'
        }],
    }
    response = client.start_build(**build_params)
    print(json.dumps(response, indent=4, sort_keys=True, default=str))
