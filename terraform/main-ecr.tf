resource "aws_ecr_pull_through_cache_rule" "k3s" {
  for_each              = local.ecr_pull_through_caches
  ecr_repository_prefix = "${local.prefix}-${local.suffix}-${each.key}"
  upstream_registry_url = each.value
}

resource "aws_ecr_repository" "k3s" {
  for_each             = toset(var.container_images)
  name                 = "${local.prefix}-${local.suffix}-codebuild/${element(split(":", each.key), 0)}"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.k3s["ecr"].arn
  }

  tags = {
    Name = "${local.prefix}-${local.suffix}-codebuild/${element(split(":", each.key), 0)}"
  }
}
