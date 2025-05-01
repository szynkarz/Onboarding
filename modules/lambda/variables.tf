variable "region" {
  default = "eu-central-1"
}

variable "vpc_id" {
}


variable "base_tag" {
  default = "lambda"
}

variable "email_notifications" {
}

variable "interval_minutes" {
}

variable "failure_threshold" {

}

variable "endpoint_urls" {
}

variable "subnet_ids" {
}
