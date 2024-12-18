output "alb_dns_name" {
  value = aws_alb.this.dns_name
}

output "alb_zone_id" {
  value = aws_alb.this.zone_id
}

output "alb_arn" {
  value = aws_alb.this.arn
}

output "lb_security_group_id" {
  value = aws_security_group.this.id
}