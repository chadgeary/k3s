## autoscaling
resource "aws_iam_service_linked_role" "cloudk3s" {
  aws_service_name = "autoscaling.amazonaws.com"
  custom_suffix    = "${local.prefix}-${local.suffix}"
}

resource "aws_iam_policy" "cloudk3s-ec2-passrole" {
  name   = "${local.prefix}-${local.suffix}-ec2-passrole"
  path   = "/"
  policy = data.aws_iam_policy_document.cloudk3s-ec2-passrole.json
}

resource "aws_iam_user_policy_attachment" "cloudk3s-ec2-passrole" {
  user       = element(split("/", data.aws_caller_identity.cloudk3s.arn), 1)
  policy_arn = aws_iam_policy.cloudk3s-ec2-passrole.arn
}

## instances
resource "aws_iam_role" "cloudk3s-ec2" {
  name               = "${local.prefix}-${local.suffix}-ec2"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.cloudk3s-ec2-trust.json
}

resource "aws_iam_policy" "cloudk3s-ec2" {
  name   = "${local.prefix}-${local.suffix}-ec2"
  path   = "/"
  policy = data.aws_iam_policy_document.cloudk3s-ec2.json
}

# attachment(s)
resource "aws_iam_role_policy_attachment" "cloudk3s-ec2" {
  role       = aws_iam_role.cloudk3s-ec2.name
  policy_arn = aws_iam_policy.cloudk3s-ec2.arn
}

resource "aws_iam_role_policy_attachment" "cloudk3s-ec2-managed" {
  role       = aws_iam_role.cloudk3s-ec2.name
  policy_arn = data.aws_iam_policy.cloudk3s-ec2-managed.arn
}

resource "aws_iam_instance_profile" "cloudk3s-ec2" {
  name = "${local.prefix}-${local.suffix}-ec2"
  role = aws_iam_role.cloudk3s-ec2.name
}

## lambda
resource "aws_iam_role" "cloudk3s-lambda-getk3s" {
  name               = "${local.prefix}-${local.suffix}-lambda-getk3s"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.cloudk3s-lambda-getk3s-trust.json
}

resource "aws_iam_policy" "cloudk3s-lambda-getk3s" {
  name   = "${local.prefix}-${local.suffix}-lambda-getk3s"
  path   = "/"
  policy = data.aws_iam_policy_document.cloudk3s-lambda-getk3s.json
}

resource "aws_iam_role_policy_attachment" "cloudk3s-lambda-getk3s" {
  role       = aws_iam_role.cloudk3s-lambda-getk3s.name
  policy_arn = aws_iam_policy.cloudk3s-lambda-getk3s.arn
}

resource "aws_iam_role_policy_attachment" "cloudk3s-lambda-getk3s-managed-1" {
  role       = aws_iam_role.cloudk3s-lambda-getk3s.name
  policy_arn = data.aws_iam_policy.cloudk3s-lambda-getk3s-managed-1.arn
}

resource "aws_iam_role_policy_attachment" "cloudk3s-lambda-getk3s-managed-2" {
  role       = aws_iam_role.cloudk3s-lambda-getk3s.name
  policy_arn = data.aws_iam_policy.cloudk3s-lambda-getk3s-managed-2.arn
}
