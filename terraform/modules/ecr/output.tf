output "repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "proxy_endpoint" {
  value = data.aws_ecr_authorization_token.token.proxy_endpoint
}

output "user_name" {
  value = data.aws_ecr_authorization_token.token.user_name
}

output "password" {
  value = data.aws_ecr_authorization_token.token.password
}