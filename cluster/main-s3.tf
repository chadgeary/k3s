# bucket
resource "aws_s3_bucket" "cloudk3s" {
  bucket        = "${local.prefix}-${local.suffix}"
  force_destroy = true
}

# acl
resource "aws_s3_bucket_acl" "cloudk3s" {
  bucket = aws_s3_bucket.cloudk3s.id
  acl    = "private"
}

# versioning
resource "aws_s3_bucket_versioning" "cloudk3s" {
  bucket = aws_s3_bucket.cloudk3s.id
  versioning_configuration {
    status = "Enabled"
  }
}

# encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudk3s" {
  bucket = aws_s3_bucket.cloudk3s.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudk3s["s3"].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# access policy
resource "aws_s3_bucket_policy" "cloudk3s" {
  bucket = aws_s3_bucket.cloudk3s.id
  policy = data.aws_iam_policy_document.cloudk3s-s3.json
}

# public access policy
resource "aws_s3_bucket_public_access_block" "cloudk3s" {
  bucket                  = aws_s3_bucket.cloudk3s.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# s3 objects (playbook)
resource "aws_s3_object" "files" {
  for_each       = fileset("scripts/", "*")
  bucket         = aws_s3_bucket.cloudk3s.id
  key            = "scripts/${each.value}"
  content_base64 = base64encode(file("${path.module}/scripts/${each.value}"))
  kms_key_id     = aws_kms_key.cloudk3s["s3"].arn
}
