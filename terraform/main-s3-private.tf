# bucket
resource "aws_s3_bucket" "k3s-private" {
  bucket        = "${local.prefix}-${local.suffix}-private"
  force_destroy = true
}

# acl
resource "aws_s3_bucket_acl" "k3s-private" {
  bucket = aws_s3_bucket.k3s-private.id
  acl    = "private"
}

# versioning
resource "aws_s3_bucket_versioning" "k3s-private" {
  bucket = aws_s3_bucket.k3s-private.id
  versioning_configuration {
    status = "Enabled"
  }
}

# encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "k3s-private" {
  bucket = aws_s3_bucket.k3s-private.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.k3s["s3"].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# access policy
resource "aws_s3_bucket_policy" "k3s-private" {
  bucket = aws_s3_bucket.k3s-private.id
  policy = data.aws_iam_policy_document.k3s-s3-private.json
}

# public access policy
resource "aws_s3_bucket_public_access_block" "k3s-private" {
  bucket                  = aws_s3_bucket.k3s-private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# s3 objects (./scripts/ -> s3://scripts/)
resource "aws_s3_object" "scripts" {
  for_each       = fileset("../scripts/", "**")
  bucket         = aws_s3_bucket.k3s-private.id
  key            = "scripts/${each.value}"
  content_base64 = base64encode(file("../scripts/${each.value}"))
  kms_key_id     = aws_kms_key.k3s["s3"].arn
}

# s3 objects (for each ./charts/src/dir -> s3://scripts/charts/each.zip)
resource "aws_s3_object" "charts" {
  for_each    = data.archive_file.charts
  bucket      = aws_s3_bucket.k3s-private.id
  key         = "scripts/charts/${element(split("/", each.value.output_path), length(split("/", each.value.output_path)) - 1)}"
  source      = each.value.output_path
  source_hash = each.value.output_base64sha256
  kms_key_id  = aws_kms_key.k3s["s3"].arn
}

# s3 objects (for each var.container_images -> s3://containers/each.zip)
resource "aws_s3_object" "containers" {
  for_each    = data.archive_file.containers
  bucket      = aws_s3_bucket.k3s-private.id
  key         = each.value.output_path
  source      = each.value.output_path
  source_hash = each.value.output_base64sha256
  kms_key_id  = aws_kms_key.k3s["s3"].arn
}
