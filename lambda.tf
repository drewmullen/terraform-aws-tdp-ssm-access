data "archive_file" "patch_now" {
  type        = "zip"
  source_file = "${path.module}/files/patch_now.py"
  output_path = "${path.module}/builds/patch_now.zip"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "patch_now" {
  statement {
    sid     = "SendPatchBaselineToThisInstance"
    actions = ["ssm:SendCommand"]
    resources = [
      local.patch_document_arn,
      local.instance_arn,
    ]
  }

  statement {
    sid = "WritePatchLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.patch_now.arn}:*"]
  }
}

resource "aws_iam_role" "patch_now" {
  name               = local.patch_function_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  description        = "Sends AWS-RunPatchBaseline to the ${var.developer_portal_application} VM."

  tags = {
    Name = local.patch_function_name
  }
}

resource "aws_iam_role_policy" "patch_now" {
  name   = "patch"
  role   = aws_iam_role.patch_now.id
  policy = data.aws_iam_policy_document.patch_now.json
}

resource "aws_cloudwatch_log_group" "patch_now" {
  name              = "/aws/lambda/${local.patch_function_name}"
  retention_in_days = 14
}

resource "aws_lambda_function" "patch_now" {
  function_name    = local.patch_function_name
  description      = "Starts AWS-RunPatchBaseline on the ${var.developer_portal_application} VM. Invoked by the patch_now action."
  role             = aws_iam_role.patch_now.arn
  filename         = data.archive_file.patch_now.output_path
  source_code_hash = data.archive_file.patch_now.output_base64sha256
  handler          = "patch_now.handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      INSTANCE_ID = local.instance_id
    }
  }

  tags = {
    Name = local.patch_function_name
  }

  depends_on = [
    aws_iam_role_policy.patch_now,
    aws_cloudwatch_log_group.patch_now,
  ]
}
