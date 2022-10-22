resource "random_string" "suffix" {
  length  = 2
  upper   = false
  special = false
}

resource "local_file" "k3s" {
  filename        = "./connect.sh"
  file_permission = "0700"
  content = templatefile(
    "./connect.sh.tftpl",
    {
      PROFILE = var.aws_profile
      REGION  = var.aws_region
      PREFIX  = local.prefix
      SUFFIX  = local.suffix
    }
  )
}

resource "local_file" "irsa" {
  filename        = "./manifests/irsa.yaml"
  file_permission = "0600"
  content = templatefile(
    "./irsa.yaml.tftpl",
    {
      ACCOUNT  = data.aws_caller_identity.k3s.account_id
      REGION   = var.aws_region
      ROLE_ARN = aws_iam_role.k3s-irsa.arn
      PREFIX   = local.prefix
      SUFFIX   = local.suffix
    }
  )
}
