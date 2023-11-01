// =================================================================
// Mainline Branch protections
// =================================================================

resource "aws_codecommit_approval_rule_template" "approvalrule-mainline" {
  name        = "${var.AWS_REPOSITORY_NAME}-approvalrule-mainline"
  description = "foobar"

  content = jsonencode({
    Version               = "2018-11-08"
    DestinationReferences = "${local.MAINLINE_BRANCHES_ARRAY}"
    Statements = [{
      Type                    = "Approvers"
      NumberOfApprovalsNeeded = "${var.MAINLINE_APPROVALS}"
      ApprovalPoolMembers     = "${local.MAINLINE_APPROVERS_ARRAY}"
    }]
  })
}

resource "aws_codecommit_approval_rule_template_association" "approval-rule-association-mainline" {
  approval_rule_template_name = aws_codecommit_approval_rule_template.approvalrule-mainline.name
  repository_name             = "${var.AWS_REPOSITORY_NAME}"
}

resource "aws_iam_policy" "branch-protection-policy-mainline" {
  name        = "${var.AWS_REPOSITORY_NAME}-mainline"
  description = "IAM policy to protect mainline branches of the ${var.AWS_REPOSITORY_NAME} repo"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Deny",
        Action = [
                "codecommit:CreateCommit",
                "codecommit:GitPush",
                "codecommit:DeleteBranch",
                "codecommit:PutFile",
                "codecommit:MergeBranchesByFastForward",
                "codecommit:MergeBranchesBySquash",
                "codecommit:MergeBranchesByThreeWay",
                "codecommit:MergePullRequestByFastForward",
                "codecommit:MergePullRequestBySquash",
                "codecommit:MergePullRequestByThreeWay"
        ]
        Resource = "${local.REPO_ARN}",
        Condition = {
          StringEqualsIfExists = {
            "codecommit:References" = "${local.MAINLINE_BRANCHES_ARRAY}"
          }
          "Null": {
            "codecommit:References": "false"
          }
        }
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "policy-attachment-mainline" {
  for_each = toset(data.aws_iam_users.all-users.names)

  user = each.value
  policy_arn = aws_iam_policy.branch-protection-policy-mainline.arn
}

// =================================================================
// Release Branch protections
// =================================================================

resource "aws_codecommit_approval_rule_template" "approvalrule-release" {
  name        = "${var.AWS_REPOSITORY_NAME}-approvalrule-release"
  description = "foobar"

  content = jsonencode({
    Version               = "2018-11-08"
    DestinationReferences = "${local.RELEASE_BRANCHES_ARRAY}"
    Statements = [{
      Type                    = "Approvers"
      NumberOfApprovalsNeeded = "${var.RELEASE_APPROVALS}"
      ApprovalPoolMembers     = "${local.RELEASE_APPROVERS_ARRAY}"
    }]
  })
}

resource "aws_codecommit_approval_rule_template_association" "approval-rule-association-release" {
  approval_rule_template_name = aws_codecommit_approval_rule_template.approvalrule-release.name
  repository_name             = "${var.AWS_REPOSITORY_NAME}"
}

resource "aws_iam_policy" "branch-protection-policy-release" {
  name        = "${var.AWS_REPOSITORY_NAME}-release"
  description = "IAM policy to protect release branches of the ${var.AWS_REPOSITORY_NAME} repo"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Deny",
        Action = [
                "codecommit:CreateCommit",
                "codecommit:GitPush",
                "codecommit:DeleteBranch",
                "codecommit:PutFile",
                "codecommit:MergeBranchesByFastForward",
                "codecommit:MergeBranchesBySquash",
                "codecommit:MergeBranchesByThreeWay",
                "codecommit:MergePullRequestByFastForward",
                "codecommit:MergePullRequestBySquash",
                "codecommit:MergePullRequestByThreeWay"
        ]
        Resource = "${local.REPO_ARN}",
        Condition = {
          StringLikeIfExists = {
            "codecommit:References" = "${local.RELEASE_BRANCHES_ARRAY}"
          }
          "Null": {
            "codecommit:References": "false"
          }
        }
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "policy-attachment-release" {
  for_each = toset(data.aws_iam_users.all-users.names)

  user = each.value
  policy_arn = aws_iam_policy.branch-protection-policy-release.arn
}

