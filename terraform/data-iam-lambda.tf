data "aws_iam_policy" "cloudk3s-lambda-getk3s-managed-1" {
  arn = "arn:${data.aws_partition.cloudk3s.partition}:iam::aws:policy/AmazonSSMFullAccess"
}

data "aws_iam_policy" "cloudk3s-lambda-getk3s-managed-2" {
  arn = "arn:${data.aws_partition.cloudk3s.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "cloudk3s-lambda-getk3s-trust" {
  statement {
    sid = "ForLambdaOnly"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudk3s-lambda-getk3s" {

  statement {
    sid = "ListBucket"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.cloudk3s.arn,
      "${aws_s3_bucket.cloudk3s.arn}/data/*",
      "${aws_s3_bucket.cloudk3s.arn}/scripts/*"
    ]
  }

  statement {
    sid = "UseKMSLambda"
    actions = [
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.cloudk3s["lambda"].arn]
  }

  statement {
    sid = "UseKMSS3"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.cloudk3s["s3"].arn]
  }

}