
variable "domain_name" {
  default = "shynkaruk.me"
}

variable "ami_id" {
  default = "ami-0bc67ba7331a0b9f6"
}

variable "key_name" {
  default = "key"
}

variable "instance_type" {
  default = "t3.small"
}

variable "alb_base_tag" {
  default = "elk"
}

variable "asg_max_size" {
  default = 5
}

variable "asg_min_size" {
  default = 2
}

variable "user_data" {
}

variable "region" {
  default = "eu-central-1"
}

variable "vpc_id" {
}

variable "az_list" {
  default = ["a", "b"]
}

variable "cidr_block" {
  default = "10.0.0.0/16"
}

variable "gateway_id" {
}

variable "port" {
  default = 80
  type    = number
}

variable "alb_dns_name" {
}

