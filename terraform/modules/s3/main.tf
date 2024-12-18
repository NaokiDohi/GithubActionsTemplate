resource "aws_s3_bucket" "this" {
  bucket              = "${var.service_name}-${var.env}"
  bucket_prefix       = null
  force_destroy       = null
  object_lock_enabled = false
}