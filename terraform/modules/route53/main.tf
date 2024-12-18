resource "aws_acm_certificate" "this" {
  domain_name               = data.aws_route53_zone.this.name
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_record" "main" {
  name    = data.aws_route53_zone.this.name
  zone_id = data.aws_route53_zone.this.id
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
  }
}

####
# 検証用のDNSレコードの作成と検証をします。
####
# 検証用DNSレコードの作成
resource "aws_route53_record" "valid" {
  # AWS Provider 3.0.0から記載方法が変わったので注意
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  zone_id = data.aws_route53_zone.this.id
  ttl     = 60

  depends_on = [aws_acm_certificate.this]
}

# DNSレコードの検証
resource "aws_acm_certificate_validation" "valid" {
  certificate_arn = aws_acm_certificate.this.arn
  # AWS Provider 3.0.0から記載方法が変わったので注意
  validation_record_fqdns = [for record in aws_route53_record.valid : record.fqdn]
}