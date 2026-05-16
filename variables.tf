variable "aws_region" {
  description = "AWS region where the hub Transit Gateway is created."
  type        = string
  default     = "ap-southeast-1"
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
  default     = "group-9"
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

variable "db_username" {
  description = "Master username for the RDS instance."
  type        = string
  default     = "eduadmin"
}

variable "db_password" {
  description = "Master password for the RDS instance. Keep this secret; override via tfvars or environment."
  type        = string
  sensitive   = true
}

variable "vpn_client_cidr" {
  description = "CIDR block allocated for Client VPN clients (supernet)."
  type        = string
  default     = "172.16.0.0/22"
}

variable "dmz_cidr" {
  description = "CIDR block used by the DMZ VPC."
  type        = string
  default     = "10.10.2.0/24"
}

variable "ingress_cidr" {
  description = "CIDR block used by the Ingress/ALB VPC."
  type        = string
  default     = "10.10.0.0/24"
}

variable "instance_type" {
  description = "Default EC2 instance type for application servers."
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class for the application database."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage (GB) for the RDS instance."
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "Major engine version for RDS (e.g. MySQL 8.0)."
  type        = string
  default     = "8.0"
}

variable "base_domain" {
  description = "Base internal domain used for private Route53 records."
  type        = string
  default     = "educloud.internal"
}
