resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name = "/${var.basedir}/${each.key}"
  type = "SecureString"
  # overwrite = false
  value = each.value

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}