terraform {
  backend "s3" {
    bucket = "terraformbackend5521"
    region = "eu-central-1"
    key    = "elk.tfstate"
  }
}

provider "aws" {
  region = var.region
}

locals {
  wordpress_subnet_a     = module.vpc.private_subnets[0]
  wordpress_subnet_b     = module.vpc.private_subnets[1]
  elasticsearch_subnet_a = module.vpc.private_subnets[2]
  elasticsearch_subnet_b = module.vpc.private_subnets[3]
  lambda_subnet          = module.vpc.private_subnets[4]

  rds_subnet_a = module.vpc.database_subnets[0]
  rds_subnet_b = module.vpc.database_subnets[1]

  public_subnet_a = module.vpc.public_subnets[0]
  public_subnet_b = module.vpc.public_subnets[1]

}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = var.vpc_name
  cidr   = var.cidr_block
  azs    = ["${var.region}a", "${var.region}b"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  private_subnets = [
    cidrsubnet(var.cidr_block, 8, 11), # wordpress_subnet_a
    cidrsubnet(var.cidr_block, 8, 12), # wordpress_subnet_b
    cidrsubnet(var.cidr_block, 8, 21), # elasticsearch_subnet_a
    cidrsubnet(var.cidr_block, 8, 22), # elasticsearch_subnet_b
    cidrsubnet(var.cidr_block, 8, 31), # lambda_subnet
  ]

  create_database_subnet_group = true
  database_subnets = [
    cidrsubnet(var.cidr_block, 8, 101), # rds_subnet_a
    cidrsubnet(var.cidr_block, 8, 102), # rds_subnet_b
  ]

  public_subnets = [
    cidrsubnet(var.cidr_block, 8, 201), # alb_subnet_a
    cidrsubnet(var.cidr_block, 8, 202), # alb_subnet_b
  ]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false
}

module "wordpress" {
  source             = "../modules/wordpress"
  domain_name        = var.domain_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = [local.wordpress_subnet_a, local.wordpress_subnet_b]
  public_subnet_ids  = [local.public_subnet_a, local.public_subnet_b]
  db_subnet_group    = module.vpc.database_subnet_group_name

  base_tag = "wordpress"
}

module "elk" {
  source             = "../modules/elk"
  kibana_domain_name = "kibana.${var.domain_name}"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = [local.elasticsearch_subnet_a, local.elasticsearch_subnet_b]
  public_subnet_ids  = [local.public_subnet_a, local.public_subnet_b]

  base_tag = "elk"
}

module "lambda" {
  source              = "../modules/lambda"
  endpoint_urls       = var.endpoint_urls
  email_notifications = var.email_notifications
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = [local.lambda_subnet]
  interval_minutes    = 5
  failure_threshold   = 3

  base_tag = "lambda"
}
