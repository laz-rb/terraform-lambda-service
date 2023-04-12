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

data "aws_iam_policy_document" "logs" {
  statement {
    effect    = "Allow"
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "logs" {
  name        = "${var.name}-logs"
  description = "Write logs from Lambda"
  policy      = data.aws_iam_policy_document.logs.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.logs.arn
}

#-----------------------------------------------------------
# Lambda
#-----------------------------------------------------------
resource "aws_lambda_function" "this" {
  function_name = var.name
  runtime       = var.runtime
  role          = aws_iam_role.this.arn
  handler       = var.handler
  filename      = var.filename

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
  name = "/aws/lambda/${var.name}"
  retention_in_days = var.cloudwatch_log_group_retention

  tags = var.tags
}

#-----------------------------------------------------------
# API Gateway
#-----------------------------------------------------------
resource "aws_apigatewayv2_stage" "this" {
  name        = var.name
  api_id      = var.apigateway_api_id
  auto_deploy = true

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "this" {
  api_id = var.apigateway_api_id

  integration_uri    = aws_lambda_function.this.invoke_arn
  integration_type   = var.apigateway_integration_type
  integration_method = var.apigateway_integration_method
}

resource "aws_apigatewayv2_route" "this" {
  api_id = var.apigateway_api_id

  route_key = "${var.apigateway_route_key_method} ${var.apigateway_route_key_path}"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_apigatewayv2_domain_name" "this" {
  count = var.custom_dns_enabled ? 1 : 0

  domain_name = var.custom_dns

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.this.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [aws_acm_certificate_validation.this]
}

resource "aws_apigatewayv2_api_mapping" "this" {
  count = var.custom_dns_enabled ? 1 : 0

  api_id      = var.apigateway_api_id
  domain_name = aws_apigatewayv2_domain_name.this.id
  stage       = aws_apigatewayv2_stage.this.id
}

#-----------------------------------------------------------
# AWS Certificate Manger
#-----------------------------------------------------------
resource "aws_acm_certificate" "this" {
  count = var.custom_dns_enabled ? 1 : 0

  domain_name       = var.custom_dns
  validation_method = "DNS"

  tags = var.tags
}

resource "aws_acm_certificate_validation" "this" {
  count = var.custom_dns_enabled ? 1 : 0

  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.api_validation : record.fqdn]
}

#-----------------------------------------------------------
# Route53
#-----------------------------------------------------------
data "aws_route53_zone" "this" {
  count = var.custom_dns_enabled ? 1 : 0

  name         = var.hosted_zone
  private_zone = false

  tags = var.tags
}

resource "aws_route53_record" "api_validation" {
  for_each = var.custom_dns_enabled ? {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

resource "aws_route53_record" "api" {
  count = var.custom_dns_enabled ? 1 : 0

  name    = aws_apigatewayv2_domain_name.this.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.this.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.this.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.this.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
