# Secrets
resource "aws_ssm_parameter" "k3s" {
  for_each = var.secrets
  name     = "/${local.prefix}-${local.suffix}/${each.key}"
  type     = "SecureString"
  key_id   = aws_kms_key.k3s["ssm"].key_id
  value    = each.value
}

# Document
resource "aws_ssm_document" "k3s" {
  name          = "${local.prefix}-${local.suffix}"
  document_type = "Command"
  content       = <<DOC
  {
    "schemaVersion": "2.2",
    "description": "Shell Script via SSM",
    "parameters": {
    "SourceType": {
      "description": "(Optional) Specify the source type.",
      "type": "String",
      "allowedValues": [
      "GitHub",
      "S3"
      ]
    },
    "SourceInfo": {
      "description": "Specify 'path'. Important: If you specify S3, then the IAM instance profile on your managed instances must be configured with read access to Amazon S3.",
      "type": "StringMap",
      "displayType": "textarea",
      "default": {}
    },
    "ShellScriptFile": {
      "type": "String",
      "description": "(Optional) The shell script to run (including relative path). If the main file is located in the ./automation directory, then specify automation/script.sh.",
      "default": "hello-world.sh",
      "allowedPattern": "[(a-z_A-Z0-9\\-)/]+(.sh|.yaml)$"
    },
    "EnvVars": {
      "type": "String",
      "description": "(Optional) Additional variables to pass at runtime. Enter key/value pairs separated by a space. For example: color=red flavor=cherry",
      "default": "",
      "displayType": "textarea"
    }
    },
    "mainSteps": [
    {
      "action": "aws:downloadContent",
      "name": "downloadContent",
      "inputs": {
      "SourceType": "{{ SourceType }}",
      "SourceInfo": "{{ SourceInfo }}"
      }
    },
    {
      "action": "aws:runShellScript",
      "maxAttempts": 10,
      "name": "runShellScript",
      "inputs": {
      "runCommand": [
        "#!/bin/bash",
        "for zip in $(find -iname '*.zip'); do",
        "  unzip -o $zip",
        "done",
        "ShellScriptFile=\"{{ShellScriptFile}}\"",
        "export {{EnvVars}}",
        "if [ ! -f  \"$${ShellScriptFile}\" ] ; then",
        "   echo \"The specified ShellScript file doesn't exist in the downloaded bundle. Please review the relative path and file name.\" >&2",
        "   exit 2",
        "fi",
        "chmod +x \"$${ShellScriptFile}\" && /bin/bash ./\"$${ShellScriptFile}\""
      ]
      }
    }
    ]
  }
DOC
}

## association (bootstrap.sh)
resource "aws_ssm_association" "k3s" {
  for_each         = var.nodegroups
  association_name = "${local.prefix}-${local.suffix}-${each.key}"
  name             = aws_ssm_document.k3s.name
  targets {
    key    = "tag:Name"
    values = ["${each.key}.${local.prefix}-${local.suffix}.internal"]
  }
  output_location {
    s3_bucket_name = aws_s3_bucket.k3s-private.id
    s3_key_prefix  = "ssm/${each.key}"
  }
  parameters = {
    EnvVars         = "AWS_ADDON_URI=${local.aws_addon_uris[var.region]} ACCOUNT=${data.aws_caller_identity.k3s.account_id} REGION=${var.region} PREFIX=${local.prefix} SUFFIX=${local.suffix} DB_ENDPOINT=${aws_db_instance.k3s.endpoint} K3S_NODEGROUP=${each.key} K3S_URL=https://${aws_lb.k3s-private.dns_name}:6443 SECGROUP=${aws_security_group.k3s-ec2.id} VPC=${aws_vpc.k3s.id} POD_CIDR=${var.pod_cidr} NAT_GATEWAYS=${tostring(var.nat_gateways)}"
    ShellScriptFile = "bootstrap.sh"
    SourceInfo      = "{\"path\":\"https://s3.${var.region}.amazonaws.com/${aws_s3_bucket.k3s-private.id}/scripts/\"}"
    SourceType      = "S3"
  }
  depends_on = [data.aws_lambda_invocation.k3s-getk3s]
}
