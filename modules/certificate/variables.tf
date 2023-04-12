variable "hosted_zone" {
  type = string
  description = "(optional) describe your variable"
  default = ""
}

variable "custom_dns" {
  type = string
  description = "(optional) describe your variable"
  default = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
