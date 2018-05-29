variable "ami" {
  type        = "string"
  description = "The AMI to use"
}

variable "cloudfront_price_class" {
  type        = "string"
  description = "The CloudFront pricing class to use (PriceClass_All, PriceClass_200, or PriceClass_100)."
}

variable "git_repo" {
  type        = "string"
  description = "The Git repository where the site's contents are stored"
}

variable "github_secret_parameter_name" {
  type        = "string"
  description = "The name of the SSM Parameter Store parameter that contains the GitHub webhook secret"
}

variable "hugo_version" {
  type        = "string"
  description = "The Hugo version to use"
  default     = "0.41"
}

variable "instance_type" {
  type        = "string"
  description = "The EC2 instance type to use"
}

variable "postprocess_template" {
  type        = "string"
  default     = ""
  description = "The file containing commands to be run after building the site"
}

variable "preprocess_template" {
  type        = "string"
  default     = ""
  description = "The file containing commands to be run prior to building the site"
}

variable "region" {
  type        = "string"
  description = "The AWS region to use"
}

variable "site_name" {
  type        = "string"
  description = "The site name to use"
}

variable "tag_name" {
  type        = "string"
  description = "The name of the tag to apply to created resources"
}

variable "webhooks_subdomain" {
  type        = "string"
  default     = "api"
  description = "The subdomain where the webhook API will be hosted"
}
