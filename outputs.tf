output "apigateway_url" {
  value       = join("", [aws_apigatewayv2_stage.this.invoke_url, var.apigateway_route_key_path])
  description = "API Gateway URL"
}

output "custom_dns_url" {
  value       = var.custom_dns_enabled ? join("", ["https://", aws_apigatewayv2_api_mapping.this[0].domain_name, var.apigateway_route_key_path]) : ""
  description = "Custom DNS URL"
}
