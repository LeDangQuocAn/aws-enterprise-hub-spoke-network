variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "vpc_ids" {
  type = map(string)
}

variable "public_subnet_ids" {
  type = map(list(string))
}

variable "private_subnet_ids" {
  type = map(list(string))
}

variable "ingress_alb_sg_id" {
  type = string
}

variable "app_web_sg_id" {
  type = string
}

variable "app_db_sg_id" {
  type = string
}

variable "web_acl_arn" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_allocated_storage" {
  type = number
}

variable "db_engine_version" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}
