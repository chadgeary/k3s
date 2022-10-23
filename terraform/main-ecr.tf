resource "aws_ecr_pull_through_cache_rule" "k3s-ecr" {
  ecr_repository_prefix = "${local.prefix}-${local.suffix}-ecr"
  upstream_registry_url = "public.ecr.aws"
}

resource "aws_ecr_pull_through_cache_rule" "k3s-quay" {
  ecr_repository_prefix = "${local.prefix}-${local.suffix}-quay"
  upstream_registry_url = "quay.io"
}

resource "aws_ecr_repository" "k3s-codebuild" {
  for_each             = toset(var.container_images)
  name                 = "${local.prefix}-${local.suffix}-codebuild/${element(split(":", each.key), 0)}"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${local.prefix}-${local.suffix}-codebuild"
  }
}

data "archive_file" "containers" {
  for_each = toset(var.container_images)
  type     = "zip"
  source {
    content = templatefile(
      "../templates/dockerfile.tftpl",
      {
        IMAGE = element(split(":", each.key), 0)
        TAG   = element(split(":", each.key), 1)
    })
    filename = "Dockerfile"
  }
  source {
    content = templatefile(
      "../templates/buildspec.yml.tftpl",
      {
        IMAGE   = element(split(":", each.key), 0)
        TAG     = element(split(":", each.key), 1)
        ACCOUNT = data.aws_caller_identity.k3s.account_id
        REGION  = var.aws_region
        PREFIX  = local.prefix
        SUFFIX  = local.suffix
    })
    filename = "buildspec.yml"
  }
  output_path = "./containers/${replace(element(split(":", each.key), 0), "/", "-")}.zip"
}

resource "aws_s3_object" "containers" {
  for_each       = fileset("./containers/", "*.zip")
  bucket         = aws_s3_bucket.k3s-private.id
  key            = "containers/${each.value}"
  content_base64 = filebase64("./containers/${each.value}")
  kms_key_id     = aws_kms_key.k3s["s3"].arn

  depends_on = [data.archive_file.containers]
}

resource "aws_codebuild_project" "k3s" {
  name           = "${local.prefix}-${local.suffix}-codebuild"
  description    = "${local.prefix}-${local.suffix}"
  service_role   = aws_iam_role.k3s-codebuild.arn
  encryption_key = aws_kms_key.k3s["codebuild"].arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:6.0"
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

  depends_on = [aws_iam_role_policy_attachment.k3s-codebuild, aws_cloudwatch_log_group.k3s-codebuild, aws_s3_object.containers, data.archive_file.containers]
}

resource "aws_codepipeline" "k3s" {
  for_each = toset(var.container_images)
  name     = "containers-${local.prefix}-${local.suffix}-${replace(element(split(":", each.key), 0), "/", "-")}"
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
        S3ObjectKey          = "containers/${replace(element(split(":", each.key), 0), "/", "-")}.zip"
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

  depends_on = [data.archive_file.containers]
}
