# sns topic called by lifecycle hooks
resource "aws_sns_topic" "k3s-scaledown" {
  name              = "${local.prefix}-${local.suffix}-scaledown"
  kms_master_key_id = aws_kms_key.k3s["sns"].arn
  delivery_policy   = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}

# sns subscription for lambda
resource "aws_sns_topic_subscription" "k3s-scaledown" {
  topic_arn = aws_sns_topic.k3s-scaledown.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.k3s-scaledown.arn
}

# document to run at scaledown
resource "aws_ssm_document" "k3s-scaledown" {
  name          = "${local.prefix}-${local.suffix}-scaledown"
  document_type = "Command"
  content       = <<DOC
{
 "schemaVersion": "2.2",
 "description": "Autoscaling for k3s",
 "parameters": {
  "ASGNAME": {
   "type":"String",
   "description":"ASG Name"
  },
  "LIFECYCLEHOOKNAME": {
   "type":"String",
   "description":"LCH Name"
  }
 },
 "mainSteps": [
  {
   "action": "aws:runShellScript",
   "name": "runShellScript",
   "inputs": {
    "timeoutSeconds": "900",
    "runCommand": [
     "#!/bin/bash",
     "export LIFECYCLEHOOKNAME='{{ LIFECYCLEHOOKNAME }}'",
     "export ASGNAME='{{ ASGNAME }}'",
     "/usr/local/bin/scaledown.sh"
    ]
   }
  }
 ]
}
DOC
}
