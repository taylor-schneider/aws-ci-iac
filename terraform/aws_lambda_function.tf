# ==========================================
# Define AWSLambdaBasicExecutionRole
# ==========================================
#
# https://stackoverflow.com/questions/57288992/terraform-how-to-create-iam-role-for-aws-lambda-and-deploy-both
# https://stackoverflow.com/questions/59949808/write-aws-lambda-logs-to-cloudwatch-log-group-with-terraform
#

data "aws_iam_policy_document" "AWSLambdaTrustPolicy" {
  statement {
    actions       = ["sts:AssumeRole"]
    effect        = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "terraform-function-role" {
  name               = "terraform-function-role"
  assume_role_policy = "${data.aws_iam_policy_document.AWSLambdaTrustPolicy.json}"
}

resource "aws_iam_role_policy_attachment" "terraform-lambda-policy" {
  role       = "${aws_iam_role.terraform-function-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ===================================================
# Give Lambda Role ability To Start CodeBuild Build
# ===================================================

data "aws_iam_policy_document" "lambda-start-build" {
  statement {
    effect = "Allow"

    actions = [
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda-start-codebuild" {
  name        = "lambda-start-codebuild"
  description = "IAM Policy to allow Lambda Functions to trigger CodeBuild Builds"
  policy      = data.aws_iam_policy_document.lambda-start-build.json
}

resource "aws_iam_role_policy_attachment" "lambda-start-codebuild" {
  role       = aws_iam_role.terraform-function-role.name
  policy_arn = aws_iam_policy.lambda-start-codebuild.arn
}

# ==========================================
# Convert the .py file into a zip so we can upload it to lambda
# ==========================================

data "archive_file" "lambda-archive-file" {
  type        = "zip"
  source_file = "${path.module}/trigger_codebuild_lambda.py"
  output_path = "lambda_function_payload.zip"
}

# ==========================================
# Define the Lambda function
# ==========================================

resource "aws_lambda_function" "lambda-function" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "${path.module}/lambda_function_payload.zip"
  function_name = "${var.AWS_REPOSITORY_NAME}-codebuild-trigger"
  role          = "${aws_iam_role.terraform-function-role.arn}"

  source_code_hash = data.archive_file.lambda-archive-file.output_base64sha256

  runtime = "python3.9"
  handler = "trigger_codebuild_lambda.lambda_handler"

}


# ==========================================
# Define the trigger for the function
# ==========================================
#
# NOTE: The documentation is incorrect about specifying branches = ["all"]
#       While this will work, it will show up as "all" in the aws console
#       rather than "All branches". The tool does not allow us to set a
#       value of ["All branches"] but omitting the option will have the 
#       desired effect.


resource "aws_codecommit_trigger" "codecommit-trigger" {
  repository_name = "${aws_codecommit_repository.aws-repo.repository_name}"

  trigger {
    name            = "${var.AWS_REPOSITORY_NAME}"
    events          = ["all"]
    destination_arn = "${aws_lambda_function.lambda-function.arn}"
  }
}

# ==========================================
# Allow the lambda to trigger from code commit
# ==========================================

resource "aws_lambda_permission" "lambda-permission" {
  statement_id  = "1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-function.function_name
  principal     = "codecommit.amazonaws.com"
  source_arn    = aws_codecommit_repository.aws-repo.arn
}
