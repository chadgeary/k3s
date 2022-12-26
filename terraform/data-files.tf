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
        REGION  = var.region
        PREFIX  = local.prefix
        SUFFIX  = local.suffix
    })
    filename = "buildspec.yml"
  }
  source {
    content = templatefile(
      "../templates/multiarch.yml.tftpl",
      {
        IMAGE   = element(split(":", each.key), 0)
        TAG     = element(split(":", each.key), 1)
        ACCOUNT = data.aws_caller_identity.k3s.account_id
        REGION  = var.region
        PREFIX  = local.prefix
        SUFFIX  = local.suffix
    })
    filename = "multiarch.yml"
  }
  output_path = "containers/${replace(element(split(":", each.key), 0), "/", "-")}.zip"
}

data "archive_file" "charts" {
  for_each    = toset(distinct([for k in fileset("../charts/src", "**") : "${element(split("/", k), 0)}"]))
  type        = "zip"
  source_dir  = "../charts/src/${each.key}"
  output_path = "../charts/archives/${each.key}.zip"
}
