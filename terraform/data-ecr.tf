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
