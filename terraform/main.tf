resource "random_string" "suffix" {
  length  = 2
  upper   = false
  special = false
}

resource "local_file" "k3s" {
  filename        = "./connect.sh"
  file_permission = "0700"
  content = templatefile(
    "./connect.tftpl",
    {
      aws_profile = var.aws_profile
      aws_region  = var.aws_region
      prefix      = local.prefix
      suffix      = local.suffix
    }
  )
}
