resource "random_string" "suffix" {
  length  = 2
  upper   = false
  special = false
}

resource "local_file" "k3s" {
  filename        = "./connect.sh"
  file_permission = "0700"
  content = templatefile(
    "../templates/connect.sh.tftpl",
    {
      PROFILE = var.profile
      REGION  = var.region
      PREFIX  = local.prefix
      SUFFIX  = local.suffix
    }
  )
}

resource "local_file" "irsa" {
  filename        = "./manifests/irsa.yaml"
  file_permission = "0600"
  content = templatefile(
    "../templates/irsa.yaml.tftpl",
    {
      ACCOUNT  = data.aws_caller_identity.k3s.account_id
      REGION   = var.region
      ROLE_ARN = aws_iam_role.k3s-irsa.arn
      PREFIX   = local.prefix
      SUFFIX   = local.suffix
    }
  )
}

resource "local_file" "nginx-w-calico" {
  filename        = "./manifests/web-test.yaml"
  file_permission = "0600"
  content = templatefile(
    "../templates/web-test.yaml.tftpl",
    {
      ACCOUNT = data.aws_caller_identity.k3s.account_id
      REGION  = var.region
      PREFIX  = local.prefix
      SUFFIX  = local.suffix
    }
  )
}
