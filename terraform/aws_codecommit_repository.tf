# Import the repo if it already exists

import {
  to = aws_codecommit_repository.aws-repo
  id = "${var.AWS_REPOSITORY_NAME}"
}

# Otherwise create it

resource "aws_codecommit_repository" "aws-repo" {
  repository_name = "${var.AWS_REPOSITORY_NAME}"
}

