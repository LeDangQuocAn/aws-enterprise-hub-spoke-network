variable "aws_region" {
  description = "AWS region where the hub Transit Gateway is created."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "sprint1"
}

variable "project_name" {
  description = "Project name used in tags and resource naming."
  type        = string
  default     = "aws-enterprise-hub-spoke-network"
}

variable "owner" {
  description = "Owner tag for enterprise accountability."
  type        = string
  default     = "university-network-team"
}

variable "cost_center" {
  description = "Optional cost center tag."
  type        = string
  default     = "network-design"
}

variable "additional_tags" {
  description = "Additional tags to merge with the standard tag set."
  type        = map(string)
  default     = {}
}

variable "tgw_description" {
  description = "Optional Transit Gateway description."
  type        = string
  default     = "Core hub Transit Gateway for the university enterprise network"
}
