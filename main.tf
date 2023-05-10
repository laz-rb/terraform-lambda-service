#-----------------------------------------------------------
# IAM
#-----------------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
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
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "this" {
  // CloudWatch Logs permissions
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  // VPC permissions
  dynamic "statement" {
    for_each = var.custom_vpc_enabled ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:AssignPrivateIpAddress",
        "ec2:UnassignPrivateIpAddress"
      ]
      resources = ["*"]
    }
  }
}

resource "aws_iam_policy" "this" {
  name        = var.name
  description = "Lambda execution permissions"
  policy      = data.aws_iam_policy_document.this.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

data "aws_iam_policy_document" "rest_api_policy" {
  count = var.apigateway_version == "v1" && var.allowed_ips != null ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["execute-api:/*/*/*"]
  }

  statement {
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["execute-api:/*/*/*"]

    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values   = var.allowed_ips
    }
  }
}

#-----------------------------------------------------------
# Lambda
#-----------------------------------------------------------
resource "aws_lambda_function" "this" {
  function_name    = var.name
  runtime          = var.runtime
  role             = aws_iam_role.this.arn
  handler          = var.handler
  filename         = var.filename
  source_code_hash = filebase64sha256(var.filename)

  environment {
    variables = var.environment_variables
  }

  vpc_config {
    security_group_ids = var.security_groups_ids
    subnet_ids         = var.subnet_ids
  }

  tags = var.tags
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.apigateway_execution_arn}/*/*"
}

#-----------------------------------------------------------
# CloudWatch
#-----------------------------------------------------------
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.cloudwatch_log_group_retention

  tags = var.tags
}

#-----------------------------------------------------------
# API Gateway v1
#-----------------------------------------------------------
data "aws_api_gateway_domain_name" "this" {
  count = var.apigateway_version == "v1" && var.custom_domain_enabled ? 1 : 0

  domain_name = var.custom_domain_name
}

resource "aws_api_gateway_resource" "this" {
  count = var.apigateway_version == "v1" ? 1 : 0

  rest_api_id = var.apigateway_api_id
  parent_id   = var.apigateway_root_resource_id
  path_part   = var.apigateway_route_key_path
}

resource "aws_api_gateway_method" "this" {
  count = var.apigateway_version == "v1" ? 1 : 0

  rest_api_id   = var.apigateway_api_id
  resource_id   = aws_api_gateway_resource.this[count.index].id
  http_method   = var.apigateway_route_key_method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "this" {
  count = var.apigateway_version == "v1" ? 1 : 0

  rest_api_id             = var.apigateway_api_id
  resource_id             = aws_api_gateway_resource.this[count.index].id
  http_method             = aws_api_gateway_method.this[count.index].http_method
  integration_http_method = var.apigateway_integration_method
  type                    = var.apigateway_integration_type
  uri                     = aws_lambda_function.this.invoke_arn
}

resource "aws_api_gateway_deployment" "this" {
  count = var.apigateway_version == "v1" ? 1 : 0

  rest_api_id = var.apigateway_api_id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.this[count.index].id,
      aws_api_gateway_method.this[count.index].id,
      aws_api_gateway_integration.this[count.index].id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  count = var.apigateway_version == "v1" ? 1 : 0

  deployment_id = aws_api_gateway_deployment.this[count.index].id
  rest_api_id   = var.apigateway_api_id
  stage_name    = var.name
}

resource "aws_api_gateway_base_path_mapping" "this" {
  count = var.apigateway_version == "v1" && var.custom_domain_enabled ? 1 : 0

  api_id      = var.apigateway_api_id
  stage_name  = aws_api_gateway_stage.this[count.index].stage_name
  domain_name = data.aws_api_gateway_domain_name.this[count.index].domain_name
  base_path   = aws_api_gateway_stage.this[count.index].stage_name
}

resource "aws_api_gateway_rest_api_policy" "this" {
  count = var.apigateway_version == "v1" && var.allowed_ips != null ? 1 : 0

  rest_api_id = var.apigateway_api_id
  policy      = data.aws_iam_policy_document.rest_api_policy[count.index].json
}

#-----------------------------------------------------------
# API Gateway v2
#-----------------------------------------------------------
resource "aws_apigatewayv2_integration" "this" {
  count = var.apigateway_version == "v2" ? 1 : 0

  api_id = var.apigateway_api_id

  integration_uri    = aws_lambda_function.this.invoke_arn
  integration_type   = var.apigateway_integration_type
  integration_method = var.apigateway_integration_method
}

resource "aws_apigatewayv2_route" "this" {
  count = var.apigateway_version == "v2" ? 1 : 0

  api_id = var.apigateway_api_id

  route_key = "${var.apigateway_route_key_method} /${var.apigateway_route_key_path}"
  target    = "integrations/${aws_apigatewayv2_integration.this[count.index].id}"
}
