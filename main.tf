############# IAM #############
data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.this.json
}

############# Lambda #############
resource "aws_lambda_function" "this" {
  function_name = var.name
  runtime       = var.runtime
  role          = aws_iam_role.this.arn
  handler       = var.handler
  filename      = var.filename
}

############# CloudWatch #############
resource "aws_cloudwatch_log_group" "this" {
  name = "/aws/lambda/${var.name}"
  retention_in_days = var.cloudwatch_log_group_retention
}

############# API GateWay #############
resource "aws_apigatewayv2_stage" "dev" {
  name        = "dev"
  api_id      = aws_apigatewayv2_api.this.id
  auto_deploy = true
}
