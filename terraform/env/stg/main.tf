
# 共通的に使用する値を変数として定義
locals {
  vars              = yamldecode(file("./envfile/env.yaml"))
  env               = local.vars.env
  domain_name       = local.vars.domain
  db_master_user    = local.vars.db_master_user
  database_name     = local.vars.database_name
  table_name        = local.vars.table_name
  cidr              = "192.168.1.0/24"
  public_subnets    = ["192.168.1.64/28", "192.168.1.80/28"]
  private_subnets   = ["192.168.1.32/28", "192.168.1.48/28"]
  rds_subnets       = ["192.168.1.0/28", "192.168.1.16/28"]
  azs               = ["ap-northeast-1a", "ap-northeast-1c"]
  service_name      = local.vars.service_name
  ssm_parameters    = local.vars.ssm_parameters
  ecs               = local.vars.ecs
}

module "vpc" {
  source = "../../modules/vpc"

  service_name    = local.service_name
  cidr            = local.cidr
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
  rds_subnets     = local.rds_subnets
  azs             = local.azs
  env             = local.env
}

module "alb" {
  source = "../../modules/alb"

  service_name         = local.service_name
  env                  = local.env
  vpc_id               = module.vpc.vpc.vpc_id
  subnets              = module.vpc.vpc.public_subnets
  domain_name          = local.domain_name
  acm_arn              = module.route53.acm_arn
  alb_target_group_arn = module.ecs.alb_target_group_arn
  lb_listener_http_arn = module.ecs.lb_listener_http_arn

  # depends_on = [module.vpc]
}

module "route53" {
  source = "../../modules/route53"

  env          = local.env
  service_name = local.service_name
  domain_name  = local.domain_name
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id

  # depends_on = [module.vpc, module.alb]
}

module "ecs" {
  source = "../../modules/ecs"
  env                  = local.env
  vpc_id               = module.vpc.vpc.vpc_id
  ssm_parameters       = local.ecs.ssm_parameters
  subnets              = module.vpc.vpc.private_subnets
  alb_arn              = module.alb.alb_arn
  lb_security_group_id = module.alb.lb_security_group_id
  service_name         = local.service_name
  ecr_url              = module.ecr.repository_url

  depends_on = [
    module.ssm-parameters
  ]
}

module "rds" {
  source = "../../modules/rds"

  env            = local.env
  service_name   = local.service_name
  db_master_user = local.db_master_user
  database_name  = local.database_name
  rds_table_name = local.table_name
  # ssm_parameters           = local.ecs.ssm_parameters
  vpc_id                   = module.vpc.vpc.vpc_id
  azs                      = local.azs
  db_subnet_group_name     = module.vpc.vpc.database_subnet_group
  access_allow_cidr_blocks = module.vpc.vpc.private_subnets_cidr_blocks

  depends_on = [
    module.vpc,
    module.alb,
    module.route53,
    # module.ssm-parameters
  ]
}

module "ecr" {
  source = "../../modules/ecr"

  env          = local.env
  service_name = local.service_name
}

module "s3" {
  source = "../../modules/s3"

  env          = local.env
  service_name = local.service_name
}

module "ssm-parameters" {
  source  = "../../modules/ssm-parameter"
  basedir = local.ssm_parameters.basedir
  parameters = {
    for k in local.ssm_parameters.keys : k => "change-me"
  }
}

# module "bastion" {
#   source = "../../modules/bastion"

#   env          = local.env
#   service_name = local.service_name
#   vpc_id       = module.vpc.vpc.vpc_id
#   subnet_id    = module.vpc.vpc.private_subnets[0]

#   depends_on = [
#     module.vpc,
#     module.alb,
#     module.route53,
#   ]
# }