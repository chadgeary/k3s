resource "aws_cloudwatch_event_rule" "k3s-r53updater" {
  name                = "${local.prefix}-${local.suffix}-r53updater"
  schedule_expression = "rate(1 minute)"
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "k3s-r53updater" {
  arn  = aws_lambda_function.k3s-r53updater.arn
  rule = aws_cloudwatch_event_rule.k3s-r53updater.id
  depends_on = [
    aws_iam_role_policy_attachment.k3s-lambda-r53updater,
    aws_iam_role_policy_attachment.k3s-lambda-r53updater-managed-1,
    aws_iam_role_policy_attachment.k3s-lambda-r53updater-managed-2
  ]
}
