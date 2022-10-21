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

# s3 objects (playbook)
resource "aws_s3_object" "files" {
  for_each       = fileset("../scripts/", "*")
  bucket         = aws_s3_bucket.k3s-private.id
  key            = "scripts/${each.value}"
  content_base64 = base64encode(file("../scripts/${each.value}"))
  kms_key_id     = aws_kms_key.k3s["s3"].arn
}


# bucket
resource "aws_s3_bucket" "k3s-public" {
  bucket        = "${local.prefix}-${local.suffix}-public"
  force_destroy = true
}

# acl
resource "aws_s3_bucket_acl" "k3s-public" {
  bucket = aws_s3_bucket.k3s-public.id
  acl    = "public-read"
}

# versioning
resource "aws_s3_bucket_versioning" "k3s-public" {
  bucket = aws_s3_bucket.k3s-public.id
  versioning_configuration {
    status = "Enabled"
  }
}

# access policy
resource "aws_s3_bucket_policy" "k3s-public" {
  bucket = aws_s3_bucket.k3s-public.id
  policy = data.aws_iam_policy_document.k3s-s3-public.json
}

# public access policy
resource "aws_s3_bucket_public_access_block" "k3s-public" {
  bucket                  = aws_s3_bucket.k3s-public.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}