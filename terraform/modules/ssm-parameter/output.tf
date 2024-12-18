output "parameters" {
  value = {
    for k, v in aws_ssm_parameter.this : v.name => {
      name : v.name,
      arn : v.arn,
    }
  }
}
