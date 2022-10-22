resource "aws_ecr_pull_through_cache_rule" "k3s-ecr" {
  ecr_repository_prefix = "${local.prefix}-${local.suffix}-ecr"
  upstream_registry_url = "public.ecr.aws"
}

resource "aws_ecr_pull_through_cache_rule" "k3s-quay" {
  ecr_repository_prefix = "${local.prefix}-${local.suffix}-quay"
  upstream_registry_url = "quay.io"
}
