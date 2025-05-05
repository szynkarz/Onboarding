variable "key_name" {
  default = "key"
}

variable "instance_type" {
  default = "t3.small"
}

variable "asg_max_size" {
  default = 5
}

variable "asg_min_size" {
  default = 2
}

variable "user_data" {
}

variable "vpc_id" {
}

variable "port" {
  default = 80
  type    = number
}

variable "domain_name" {
}

variable "base_tag" {
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}
