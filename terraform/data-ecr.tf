data "archive_file" "containers-arm64" {
  for_each = toset(var.container_images["arm64"])
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
        ARCH    = "arm64"
        REGION  = var.region
        PREFIX  = local.prefix
        SUFFIX  = local.suffix
    })
    filename = "buildspec.yml"
  }
  output_path = "./containers/arm64/${replace(element(split(":", each.key), 0), "/", "-")}.zip"
}

data "archive_file" "containers-x86_64" {
  for_each = toset(var.container_images["x86_64"])
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
        ARCH    = "x86_64"
        REGION  = var.region
        PREFIX  = local.prefix
        SUFFIX  = local.suffix
    })
    filename = "buildspec.yml"
  }
  output_path = "./containers/x86_64/${replace(element(split(":", each.key), 0), "/", "-")}.zip"
}

