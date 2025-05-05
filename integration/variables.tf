variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_name" {
  type    = string
  default = "vpc"
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "domain_name" {
  type = string
}

variable "email_notifications" {
  type = string
}

variable "endpoint_urls" {
  type = list(string)
}
