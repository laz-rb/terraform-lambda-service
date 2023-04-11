variable "name" {
  type = string
  description = "Name of the service. This name will be used in all resources"
}

variable "runtime" {
  type = string
  description = "(Optional) Identifier of the function's runtime. See [Runtimes](https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime) for valid values."
  default = "nodejs14.x"
}

variable "handler" {
  type = string
  description = "Function entrypoint in your code"
}

variable "filename" {
  type = string
  description = "Path to the function's deployment package within the local filesystem. Exactly one of filename, image_uri, or s3_bucket must be specified"
}

variable "cloudwatch_log_group_retention" {
  type = number
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  default = 14
}
