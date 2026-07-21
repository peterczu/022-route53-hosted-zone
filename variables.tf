variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "domain_name" {
  type    = string
  default = "idevops2026.site"
}

