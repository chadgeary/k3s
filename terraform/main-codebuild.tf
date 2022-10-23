resource "aws_lb" "k3s-private" {
  name                             = "${local.prefix}-${local.suffix}-private"
  load_balancer_type               = "network"
  internal                         = true
  enable_cross_zone_load_balancing = true
  subnets                          = [for key, value in aws_subnet.k3s-private : value.id]

  tags = {
    Name = "${local.prefix}-${local.suffix}-private"
  }
}

resource "aws_codebuild_project" "k3s" {
  name           = "${local.prefix}-${local.suffix}"
  description    = "${local.prefix}-${local.suffix}"
  service_role   = aws_iam_role.k3s-codebuild.arn
  encryption_key = aws_kms_key.k3s["codebuild"].arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:6.0"
    type         = "LINUX_CONTAINER"
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.k3s.account_id
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.zk-repo.name
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }
  source {
    type = "CODEPIPELINE"
  }
  logs_config {
    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.k3s-private.id}/containers/build-log"
    }
  }
  depends_on = [aws_iam_role_policy_attachment.zk-codebuild-policy-role-attach, aws_cloudwatch_log_group.tf-nifi-cloudwatch-log-group-codebuild, aws_s3_bucket_object.zk-s3-codebuild-object]
}

resource "aws_codepipeline" "k3s" {
  name     = "${local.prefix}-${local.suffix}"
  role_arn = aws_iam_role.zk-codepipe-role.arn
  artifact_store {
    location = aws_s3_bucket.k3s-private.bucket
    type     = "S3"
    encryption_key {
      id   = aws_kms_key.k3s["s3"].arn
      type = "KMS"
    }
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      output_artifacts = ["source_output"]
      version          = "1"
      configuration = {
        S3Bucket             = aws_s3_bucket.k3s-private.bucket
        S3ObjectKey          = "zk-files/zookeeper.zip"
        PollForSourceChanges = "false"
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.k3s.name
      }
    }
  }
}