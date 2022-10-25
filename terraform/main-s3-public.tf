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
