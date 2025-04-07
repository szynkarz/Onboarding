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
  default = 3
}

variable "asg_min_size" {
  default = 1
}

variable "asg_desired_capacity" {
  default = 3
}

variable "ami_id" {
  description = "WordPress AMI ID"
  default     = "ami-0ed7a99bcb164dd1b"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "db_instance_type" {
  default = "db.t3.micro"
}

variable "allocated_storage" {
  default = 5
}

variable "domain_name" {
  description = "domain name for the load balancer"
  default     = "shynkaruk.me"
}
