variable "application_name" {
  type    = string
  default = "my-php-app"
}

variable "environment_name" {
  type    = string
  default = "my-php-app-env"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "php_version" {
  type    = string
  default = "7.4"
}

variable "key_name" {
  type    = string
  default = "key"
}
