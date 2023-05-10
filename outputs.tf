output "apigateway_endpoint" {
  value = var.apigateway_version == "v1" ? "${aws_api_gateway_deployment.this[0].invoke_url}${aws_api_gateway_stage.this[0].stage_name}/${aws_api_gateway_resource.this[0].path_part}" : ""
}

output "custom_domain_endpoint" {
  value = var.apigateway_version == "v1" ? "https://${data.aws_api_gateway_domain_name.this[0].domain_name}/${aws_api_gateway_stage.this[0].stage_name}/${aws_api_gateway_resource.this[0].path_part}" : ""
}
