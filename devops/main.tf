terraform {

  backend "s3" {
    bucket         = "teg-challenge-terraform"
    key            = "terraform/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "teg-challenge-terraform-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

######################
# Locals and Settings
######################

locals {
  app_name = var.project_name

  backend_domain = "api.${var.project_name}.quangtechnologies.com"

  app_buckets = {
    frontend = {
      name            = "frontend"
      domain          = "${var.project_name}.quangtechnologies.com"
      origin_id       = "frontendS3Origin"
      oac_name        = "frontend-oac"
      oac_description = "OAC for TEG Frontend"
    }
  }
}

module "s3" {
  source = "./modules/storage/s3"

  project_name = var.project_name
  app_buckets  = local.app_buckets
  region_id    = var.region_id

}

module "iam" {
  source = "./modules/security/iam"

  project_name = var.project_name
}

module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  az_a         = var.aza
  az_b         = var.azb
}

module "security_groups" {
  source = "./modules/security/security_groups"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}

module "alb" {
  source = "./modules/load_balancing/alb"

  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  hosted_zone_id     = var.hosted_zone_id
  alb_sg_id          = module.security_groups.alb_sg_id
  public_subnet_a_id = module.networking.public_subnet_a_id
  public_subnet_b_id = module.networking.public_subnet_b_id
  backend_domain     = local.backend_domain
}

module "ecs" {
  source = "./modules/compute/ecs"

  project_name                  = var.project_name
  public_subnet_a_id            = module.networking.public_subnet_a_id
  backend_instance_profile_name = module.iam.backend_instance_profile_name
  backend_sg_id                 = module.security_groups.backend_sg_id
  backend_task_exec_role_arn    = module.iam.backend_task_exec_role_arn
  aws_region                    = var.aws_region
  alb_target_group_arn          = module.alb.alb_target_group_arn
  backend_image_url             = var.backend_image_url
}

module "auto_scaling" {
  source = "./modules/auto_scaling"

  project_name             = var.project_name
  backend_ecs_cluster_name = module.ecs.backend_ecs_cluster_name
  backend_ecs_service_name = module.ecs.backend_ecs_service_name

  depends_on = [module.ecs]
}

module "cdn" {
  source = "./modules/cdn"

  project_name                     = var.project_name
  hosted_zone_id                   = var.hosted_zone_id
  app_buckets                      = local.app_buckets
  app_bucket_regional_domain_names = module.s3.app_bucket_regional_domain_names
  cloudfront_acm_certificate_arn   = var.cloudfront_acm_certificate_arn
}

module "route53" {
  source = "./modules/load_balancing/route53"

  hosted_zone_id = var.hosted_zone_id
  app_buckets    = local.app_buckets
  cdn_domains    = module.cdn.cdn_domains
  alb_dns_name   = module.alb.alb_dns_name
  alb_zone_id    = module.alb.alb_zone_id
  backend_domain = local.backend_domain

  depends_on = [module.cdn, module.alb]
}


