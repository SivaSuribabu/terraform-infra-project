resource "aws_s3_bucket" "bucket" {
  count = 3
  bucket = "${var.env_name}-${count.index + 1}-${var.bucket_suffix}"
  force_destroy = true
}

