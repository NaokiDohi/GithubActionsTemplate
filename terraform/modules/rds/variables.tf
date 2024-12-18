variable "env" {}
variable "vpc_id" {}
variable "azs" {}
variable "db_subnet_group_name" {}
variable "access_allow_cidr_blocks" {}
variable "service_name" {}
variable "rds_table_name" {}
# variable "ssm_parameters" {
#   type        = map(string)
#   description = <<EOF
#     {
#       "ENV_VAR_NAME": "some/ssm/parameter/key",
#     }
#   EOF
# }
variable "database_name" {
  type = string
}

variable "db_master_user" {
  type = string
}

# data "aws_ssm_parameter" "list" {
#   for_each = var.ssm_parameters
#   name     = each.value
# }
