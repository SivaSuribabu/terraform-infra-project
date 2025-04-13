provider "aws" {
  region = var.region
}

module "s3" {
  source       = "../../modules/s3"
  env_name     = "prod"
}

module "vpc" {
  source   = "../../modules/vpc"
  env_name = "prod"
  region   = var.region
  azs      = ["us-east-1a", "us-east-1b"]
}

module "asg" {
  source             = "../../modules/asg"
  env_name           = "prod"
  private_subnet_ids = module.vpc.private_subnet_ids
}


