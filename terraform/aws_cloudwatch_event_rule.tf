# ===================================================================================
# Create Cloudwatch EventRule and EventTraget to Trigger Lambda On CodeCommit Update
# ===================================================================================

resource "aws_cloudwatch_event_rule" "events-rule" {
  name        = "codecommit-${var.AWS_REPOSITORY_NAME}"
  description = "Rule to monitor the CodeCommit repo named ${var.AWS_REPOSITORY_NAME}"

  event_pattern = jsonencode({
    "detail-type" = ["CodeCommit Repository State Change"],
    "source" = ["aws.codecommit"],
    "resources" = [
      "${aws_codecommit_repository.aws-repo.arn}"
    ],
    "detail" = {
      "event" = ["referenceCreated", "referenceDeleted"],
      "repositoryId" = ["${aws_codecommit_repository.aws-repo.id}"],
      "referenceType" = ["branch"]
    }
  })
}

resource "aws_cloudwatch_event_target" "event-target" {
  rule      = aws_cloudwatch_event_rule.events-rule.name
  arn       = aws_lambda_function.lambda-function.arn
}
