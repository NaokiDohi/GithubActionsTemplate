output "rds_db_name" {
  value = aws_rds_cluster.this.database_name
}
# output "rds_table_name" { 
#     value = aws_rds_cluster.this.table_name
# }
output "vector_sotre_resource_arn" {
  value = aws_rds_cluster.this.arn
}

output "rds_vector_credentials_secret_arn" {
  value      = aws_rds_cluster.this.master_user_secret[0].secret_arn
  depends_on = [aws_rds_cluster.this]
}