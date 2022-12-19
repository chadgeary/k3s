resource "aws_codebuild_project" "k3s-arm64" {
  name           = "${local.prefix}-${local.suffix}-codebuild-arm64"
  description    = "${local.prefix}-${local.suffix}"
  service_role   = aws_iam_role.k3s-codebuild.arn
  encryption_key = aws_kms_key.k3s["codebuild"].arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-aarch64-standard:2.0"
    type            = "ARM_CONTAINER"
    privileged_mode = true
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

  depends_on = [aws_iam_role_policy_attachment.k3s-codebuild, aws_cloudwatch_log_group.k3s-codebuild-arm64, aws_s3_object.containers-arm64, data.archive_file.containers-arm64]
}

resource "aws_codebuild_project" "k3s-x86_64" {
  name           = "${local.prefix}-${local.suffix}-codebuild-x86_64"
  description    = "${local.prefix}-${local.suffix}"
  service_role   = aws_iam_role.k3s-codebuild.arn
  encryption_key = aws_kms_key.k3s["codebuild"].arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
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

  depends_on = [aws_iam_role_policy_attachment.k3s-codebuild, aws_cloudwatch_log_group.k3s-codebuild-x86_64, aws_s3_object.containers-arm64, data.archive_file.containers-arm64, aws_s3_object.containers-x86_64, data.archive_file.containers-x86_64]
}

resource "aws_codepipeline" "k3s-arm64" {
  for_each = toset(var.container_images["arm64"])
  name     = "containers-arm64-${local.prefix}-${local.suffix}-${replace(element(split(":", each.key), 0), "/", "-")}"
  role_arn = aws_iam_role.k3s-codepipeline.arn
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
        S3ObjectKey          = "containers/arm64/${replace(element(split(":", each.key), 0), "/", "-")}.zip"
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
        ProjectName = aws_codebuild_project.k3s-arm64.name
      }
    }
  }

  depends_on = [aws_iam_role_policy_attachment.k3s-codebuild, aws_cloudwatch_log_group.k3s-codebuild-x86_64, aws_s3_object.containers-arm64, data.archive_file.containers-arm64, aws_s3_object.containers-x86_64, data.archive_file.containers-x86_64]
}

resource "aws_codepipeline" "k3s-x86_64" {
  for_each = toset(var.container_images["x86_64"])
  name     = "containers-x86_64-${local.prefix}-${local.suffix}-${replace(element(split(":", each.key), 0), "/", "-")}"
  role_arn = aws_iam_role.k3s-codepipeline.arn
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
        S3ObjectKey          = "containers/x86_64/${replace(element(split(":", each.key), 0), "/", "-")}.zip"
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
        ProjectName = aws_codebuild_project.k3s-x86_64.name
      }
    }
  }

  depends_on = [aws_iam_role_policy_attachment.k3s-codebuild, aws_cloudwatch_log_group.k3s-codebuild-x86_64, aws_s3_object.containers-arm64, data.archive_file.containers-arm64, aws_s3_object.containers-x86_64, data.archive_file.containers-x86_64]
}
