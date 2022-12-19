resource "aws_ecr_pull_through_cache_rule" "k3s" {
  for_each              = local.ecr_pull_through_caches
  ecr_repository_prefix = "${local.prefix}-${local.suffix}-${each.key}"
  upstream_registry_url = each.value
}

resource "aws_ecr_repository" "k3s-arm64" {
  for_each             = toset(var.container_images["arm64"])
  name                 = "${local.prefix}-${local.suffix}-codebuild/arm64/${element(split(":", each.key), 0)}"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${local.prefix}-${local.suffix}-codebuild/arm64/${element(split(":", each.key), 0)}"
  }
}

resource "aws_ecr_repository" "k3s-x86_64" {
  for_each             = toset(var.container_images["x86_64"])
  name                 = "${local.prefix}-${local.suffix}-codebuild/x86_64/${element(split(":", each.key), 0)}"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${local.prefix}-${local.suffix}-codebuild/x86_64/${element(split(":", each.key), 0)}"
  }
}
