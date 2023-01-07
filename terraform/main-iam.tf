## autoscaling
resource "aws_iam_service_linked_role" "k3s" {
  aws_service_name = "autoscaling.amazonaws.com"
  custom_suffix    = "${local.prefix}-${local.suffix}"
}

resource "aws_iam_policy" "k3s-ec2-passrole" {
  name   = "${local.prefix}-${local.suffix}-ec2-passrole"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-ec2-passrole.json
}

resource "aws_iam_user_policy_attachment" "k3s-ec2-passrole" {
  user       = element(split("/", data.aws_caller_identity.k3s.arn), 1)
  policy_arn = aws_iam_policy.k3s-ec2-passrole.arn
}

## autoscaling lifecycle hook (sns -> ssm)
resource "aws_iam_role" "k3s-scaledown" {
  name               = "${local.prefix}-${local.suffix}-scaledown"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-scaledown-trust.json
}

resource "aws_iam_policy" "k3s-scaledown" {
  name   = "${local.prefix}-${local.suffix}-scaledown"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-scaledown.json
}

resource "aws_iam_role_policy_attachment" "k3s-scaledown" {
  role       = aws_iam_role.k3s-scaledown.name
  policy_arn = aws_iam_policy.k3s-scaledown.arn
}

## codebuild
resource "aws_iam_role" "k3s-codebuild" {
  name               = "${local.prefix}-${local.suffix}-codebuild"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-codebuild-trust.json
}

resource "aws_iam_policy" "k3s-codebuild" {
  name   = "${local.prefix}-${local.suffix}-codebuild"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-codebuild.json
}

resource "aws_iam_role_policy_attachment" "k3s-codebuild" {
  role       = aws_iam_role.k3s-codebuild.name
  policy_arn = aws_iam_policy.k3s-codebuild.arn
}

## codepipeline
resource "aws_iam_role" "k3s-codepipeline" {
  name               = "${local.prefix}-${local.suffix}-codepipeline"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-codepipeline-trust.json
}

resource "aws_iam_policy" "k3s-codepipeline" {
  name   = "${local.prefix}-${local.suffix}-codepipeline"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-codepipeline.json
}

resource "aws_iam_role_policy_attachment" "k3s-codepipeline" {
  role       = aws_iam_role.k3s-codepipeline.name
  policy_arn = aws_iam_policy.k3s-codepipeline.arn
}

## ec2 
resource "aws_iam_role" "k3s-ec2-controlplane" {
  name               = "${local.prefix}-${local.suffix}-ec2-controlplane"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-ec2-trust.json
}

resource "aws_iam_policy" "k3s-ec2-controlplane" {
  name   = "${local.prefix}-${local.suffix}-ec2-controlplane"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-ec2-controlplane.json
}

resource "aws_iam_role_policy_attachment" "k3s-ec2-controlplane" {
  role       = aws_iam_role.k3s-ec2-controlplane.name
  policy_arn = aws_iam_policy.k3s-ec2-controlplane.arn
}

resource "aws_iam_role_policy_attachment" "k3s-ec2-controlplane-managed" {
  role       = aws_iam_role.k3s-ec2-controlplane.name
  policy_arn = data.aws_iam_policy.k3s-ec2-managed.arn
}

resource "aws_iam_instance_profile" "k3s-ec2-controlplane" {
  name = "${local.prefix}-${local.suffix}-ec2-controlplane"
  role = aws_iam_role.k3s-ec2-controlplane.name
}

resource "aws_iam_role" "k3s-ec2-nodes" {
  name               = "${local.prefix}-${local.suffix}-ec2-nodes"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-ec2-trust.json
}

resource "aws_iam_policy" "k3s-ec2-nodes" {
  name   = "${local.prefix}-${local.suffix}-ec2-nodes"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-ec2-nodes.json
}

resource "aws_iam_role_policy_attachment" "k3s-ec2-nodes" {
  role       = aws_iam_role.k3s-ec2-nodes.name
  policy_arn = aws_iam_policy.k3s-ec2-nodes.arn
}

resource "aws_iam_role_policy_attachment" "k3s-ec2-nodes-managed" {
  role       = aws_iam_role.k3s-ec2-nodes.name
  policy_arn = data.aws_iam_policy.k3s-ec2-managed.arn
}

resource "aws_iam_instance_profile" "k3s-ec2-nodes" {
  name = "${local.prefix}-${local.suffix}-ec2-nodes"
  role = aws_iam_role.k3s-ec2-nodes.name
}

## lambda
resource "aws_iam_role" "k3s-lambda-getfiles" {
  name               = "${local.prefix}-${local.suffix}-lambda-getfiles"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-lambda-getfiles-trust.json
}

resource "aws_iam_policy" "k3s-lambda-getfiles" {
  name   = "${local.prefix}-${local.suffix}-lambda-getfiles"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-lambda-getfiles.json
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-getfiles" {
  role       = aws_iam_role.k3s-lambda-getfiles.name
  policy_arn = aws_iam_policy.k3s-lambda-getfiles.arn
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-getfiles-managed-1" {
  role       = aws_iam_role.k3s-lambda-getfiles.name
  policy_arn = data.aws_iam_policy.k3s-lambda-getfiles-managed-1.arn
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-getfiles-managed-2" {
  role       = aws_iam_role.k3s-lambda-getfiles.name
  policy_arn = data.aws_iam_policy.k3s-lambda-getfiles-managed-2.arn
}

resource "aws_iam_role" "k3s-lambda-oidcprovider" {
  name               = "${local.prefix}-${local.suffix}-lambda-oidcprovider"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-lambda-oidcprovider-trust.json
}

resource "aws_iam_policy" "k3s-lambda-oidcprovider" {
  name   = "${local.prefix}-${local.suffix}-lambda-oidcprovider"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-lambda-oidcprovider.json
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-oidcprovider" {
  role       = aws_iam_role.k3s-lambda-oidcprovider.name
  policy_arn = aws_iam_policy.k3s-lambda-oidcprovider.arn
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-oidcprovider-managed-1" {
  role       = aws_iam_role.k3s-lambda-oidcprovider.name
  policy_arn = data.aws_iam_policy.k3s-lambda-oidcprovider-managed-1.arn
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-oidcprovider-managed-2" {
  role       = aws_iam_role.k3s-lambda-oidcprovider.name
  policy_arn = data.aws_iam_policy.k3s-lambda-oidcprovider-managed-2.arn
}

resource "aws_iam_role" "k3s-lambda-scaledown" {
  name               = "${local.prefix}-${local.suffix}-lambda-scaledown"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-lambda-scaledown-trust.json
}

resource "aws_iam_policy" "k3s-lambda-scaledown" {
  name   = "${local.prefix}-${local.suffix}-lambda-scaledown"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-lambda-scaledown.json
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-scaledown" {
  role       = aws_iam_role.k3s-lambda-scaledown.name
  policy_arn = aws_iam_policy.k3s-lambda-scaledown.arn
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-scaledown-managed-1" {
  role       = aws_iam_role.k3s-lambda-scaledown.name
  policy_arn = data.aws_iam_policy.k3s-lambda-scaledown-managed-1.arn
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-scaledown-managed-2" {
  role       = aws_iam_role.k3s-lambda-scaledown.name
  policy_arn = data.aws_iam_policy.k3s-lambda-scaledown-managed-2.arn
}

resource "aws_iam_role" "k3s-lambda-r53updater" {
  name               = "${local.prefix}-${local.suffix}-lambda-r53updater"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-lambda-r53updater-trust.json
}

resource "aws_iam_policy" "k3s-lambda-r53updater" {
  name   = "${local.prefix}-${local.suffix}-lambda-r53updater"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-lambda-r53updater.json
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-r53updater" {
  role       = aws_iam_role.k3s-lambda-r53updater.name
  policy_arn = aws_iam_policy.k3s-lambda-r53updater.arn
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-r53updater-managed-1" {
  role       = aws_iam_role.k3s-lambda-r53updater.name
  policy_arn = data.aws_iam_policy.k3s-lambda-r53updater-managed-1.arn
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-r53updater-managed-2" {
  role       = aws_iam_role.k3s-lambda-r53updater.name
  policy_arn = data.aws_iam_policy.k3s-lambda-r53updater-managed-2.arn
}

## irsa
resource "aws_iam_role" "k3s-irsa" {
  name               = "${local.prefix}-${local.suffix}-irsa"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-irsa-trust.json
}

resource "aws_iam_policy" "k3s-irsa" {
  name   = "${local.prefix}-${local.suffix}-irsa"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-irsa.json
}

resource "aws_iam_role_policy_attachment" "k3s-irsa" {
  role       = aws_iam_role.k3s-irsa.name
  policy_arn = aws_iam_policy.k3s-irsa.arn
}

## aws-cloud-controller-manager
resource "aws_iam_role" "k3s-aws-cloud-controller-manager" {
  name               = "${local.prefix}-${local.suffix}-aws-cloud-controller-manager"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-aws-cloud-controller-manager-trust.json
}

resource "aws_iam_policy" "k3s-aws-cloud-controller-manager" {
  name   = "${local.prefix}-${local.suffix}-aws-cloud-controller-manager"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-aws-cloud-controller-manager.json
}

resource "aws_iam_role_policy_attachment" "k3s-aws-cloud-controller-manager" {
  role       = aws_iam_role.k3s-aws-cloud-controller-manager.name
  policy_arn = aws_iam_policy.k3s-aws-cloud-controller-manager.arn
}

## external-dns - only viable if using nat gateway(s)
resource "aws_iam_role" "k3s-external-dns" {
  for_each           = var.nat_gateways ? { external-dns = true } : {}
  name               = "${local.prefix}-${local.suffix}-external-dns"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-external-dns-trust["external-dns"].json
}

resource "aws_iam_policy" "k3s-external-dns" {
  for_each = var.nat_gateways ? { external-dns = true } : {}
  name     = "${local.prefix}-${local.suffix}-external-dns"
  path     = "/"
  policy   = data.aws_iam_policy_document.k3s-external-dns["external-dns"].json
}

resource "aws_iam_role_policy_attachment" "k3s-external-dns" {
  for_each   = var.nat_gateways ? { external-dns = true } : {}
  role       = aws_iam_role.k3s-external-dns["external-dns"].name
  policy_arn = aws_iam_policy.k3s-external-dns["external-dns"].arn
}
