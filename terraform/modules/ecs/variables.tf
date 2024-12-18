variable "env" {}
variable "service_name" {}
variable "vpc_id" {}
variable "subnets" {}
variable "alb_arn" {}
variable "lb_security_group_id" {}
variable "ecr_url" {}
variable "ssm_parameters" {
  type        = map(string)
  description = <<EOF
    {
      "ENV_VAR_NAME": "some/ssm/parameter/key",
    }
  EOF
}

data "aws_ssm_parameter" "list" {
  for_each = var.ssm_parameters
  name     = each.value
}

# locals {
#   ssm_data = { for item in data.aws_ssm_parameter.list : item.name => item.value }
#   ssm_values = {
#     for k, v in var.ssm_parameters : k => lookup(
#       local.ssm_data, v, "",
#     )
#   }
# }