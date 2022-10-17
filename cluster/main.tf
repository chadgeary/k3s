resource "random_string" "suffix" {
  length  = 2
  upper   = false
  special = false
}

resource "local_file" "cloudk3s" {
  filename        = "kubeconfig-and-ssmproxy.sh"
  file_permission = "0700"
  content = templatefile(
    "kubeconfig-and-ssmproxy.tftpl",
    {
      aws_profile = var.aws_profile
      aws_region  = var.aws_region
      prefix      = local.prefix
      suffix      = local.suffix
    }
  )
}

resource "local_file" "k3s-install-sh" {
  filename        = "./../scripts/install.sh"
  file_permission = "0700"
  content         = tostring(data.http.k3s-install-sh.response_body)
}
