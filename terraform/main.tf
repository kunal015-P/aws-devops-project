terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 4.0" }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source         = "./modules/vpc"
  project        = var.project
  vpc_cidr       = var.vpc_cidr
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
}

module "ecr" {
  source = "./modules/ecr"
  name   = var.ecr_repo_name
}

module "iam" {
  source  = "./modules/iam"
  project = var.project
}

module "alb" {
  source        = "./modules/alb"
  project       = var.project
  vpc_id        = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
}

module "ecs" {
  source               = "./modules/ecs"
  project              = var.project
  cluster_name         = "${var.project}-cluster"
  vpc_id               = module.vpc.vpc_id
  subnets              = module.vpc.private_subnets
  execution_role_arn   = module.iam.ecs_task_execution_role_arn
  task_role_arn        = module.iam.ecs_task_role_arn
  alb_target_group_arn = module.alb.target_group_arn
  desired_count        = var.desired_count
  ecr_repository_url   = module.ecr.repository_url
}
