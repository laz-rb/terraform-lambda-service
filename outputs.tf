output "apigateway_url" {
  value = "${aws_apigatewayv2_stage.this.invoke_url}${var.apigateway_route_key_path}"
}
