#-----------------------------------------------------------
# Common
#-----------------------------------------------------------
variable "name" {
  type        = string
  description = "Name of the API. This name will be used in all resources"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}

#-----------------------------------------------------------
# Lambda
#-----------------------------------------------------------
variable "runtime" {
  type        = string
  description = "(Optional) Identifier of the function's runtime. See [Runtimes](https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime) for valid values."
  default     = "nodejs14.x"
}

variable "handler" {
  type        = string
  description = "Function entrypoint in your code"
}

variable "filename" {
  type        = string
  description = "Path to the function's deployment package within the local filesystem. Exactly one of filename, image_uri, or s3_bucket must be specified"
}

variable "environment_variables" {
  type        = map(string)
  description = "(Optional) Map of environment variables that are accessible from the function code during execution. If provided at least one key must be present."
  default     = {}
}

#-----------------------------------------------------------
# CloudWatch Logs
#-----------------------------------------------------------
variable "cloudwatch_log_group_retention" {
  type        = number
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  default     = 14
}

#-----------------------------------------------------------
# API Gateway
#-----------------------------------------------------------
variable "apigateway_api_id" {
  type        = string
  description = "API identifier."
}

variable "apigateway_execution_arn" {
  type        = string
  description = "ARN prefix to be used in an aws_lambda_permission's source_arn attribute or in an aws_iam_policy to authorize access to the @connections API. See the Amazon [API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-control-access-iam.html) for details."
}

variable "apigateway_integration_type" {
  type        = string
  description = "(Optional) Integration type of an integration. Valid values: AWS (supported only for WebSocket APIs), AWS_PROXY, HTTP (supported only for WebSocket APIs), HTTP_PROXY, MOCK (supported only for WebSocket APIs). For an HTTP API private integration, use HTTP_PROXY."
  default     = "AWS_PROXY"
}

variable "apigateway_integration_method" {
  type        = string
  description = "(Optional) Integration's HTTP method. Must be specified if integration_type is not MOCK."
  default     = "POST"
}

variable "apigateway_route_key_method" {
  type        = string
  description = "Method for the route."
}

variable "apigateway_route_key_path" {
  type        = string
  description = "Path for the route."
  default     = "/"
}

variable "custom_dns_enabled" {
  type        = bool
  description = "(Optional) Enable custom DNS resources."
  default     = false
}

#-----------------------------------------------------------
# Route53
#-----------------------------------------------------------
variable "custom_dns" {
  type        = string
  description = "(Optional) Domain name. Must be between 1 and 512 characters in length."
  default     = ""
}

variable "hosted_zone" {
  type        = string
  description = "(Optional) Hosted Zone name of the desired Hosted Zone."
  default     = ""
}

#-----------------------------------------------------------
# VPC
#-----------------------------------------------------------
variable "custom_vpc_enabled" {
  type        = bool
  description = "(Optional) Enable deployment of the Lambda function to a custom VPC."
  default     = false
}

variable "security_groups_ids" {
  type        = list(string)
  description = "(Optional) List of security group IDs associated with the Lambda function."
  default     = []
}

variable "subnet_ids" {
  type        = list(string)
  description = "(Optional) List of subnet IDs associated with the Lambda function."
  default     = []
}
