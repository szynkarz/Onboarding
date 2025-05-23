variable "cidr_block" {
  default = "10.0.0.0/16"
}

variable "region" {
  default = "eu-central-1"
}

variable "base_tag" {
  default = "wordpress"
}

variable "az_list" {
  default = ["a", "b", "c"]
}

variable "asg_max_size" {
  default = 5
}

variable "asg_min_size" {
  default = 3
}

variable "asg_desired_capacity" {
  default = 3
}

variable "ami_id" {
  default = "ami-03250b0e01c28d196"
}

variable "key_name" {
  default = "key"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "db_instance_type" {
  default = "db.t3.micro"
}

variable "db_name" {
  default = "wordpress"
}

variable "db_username" {
  default = "user"
}


variable "allocated_storage" {
  default = 5
}

variable "domain_name" {
  default = "shynkaruk.me"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}
variable "db_subnet_group" {
  type = string
}
