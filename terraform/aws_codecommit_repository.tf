resource "aws_codecommit_repository" "aws-repo" {
  repository_name = "${var.AWS_REPOSITORY_NAME}"
}
