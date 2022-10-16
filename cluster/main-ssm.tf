# Secrets
resource "aws_ssm_parameter" "cloudk3s" {
  for_each = var.secrets
  name     = "/${local.prefix}-${local.suffix}/${each.key}"
  type     = "SecureString"
  key_id   = aws_kms_key.cloudk3s["ssm"].key_id
  value    = each.value
}

# Document
resource "aws_ssm_document" "cloudk3s" {
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

## association (cloudk3s.sh)
resource "aws_ssm_association" "cloudk3s" {
  for_each         = var.nodegroups
  association_name = "${local.prefix}-${local.suffix}-${each.key}"
  name             = aws_ssm_document.cloudk3s.name
  targets {
    key    = "tag:Name"
    values = ["${each.key}.${local.prefix}-${local.suffix}.internal"]
  }
  output_location {
    s3_bucket_name = aws_s3_bucket.cloudk3s.id
    s3_key_prefix  = "ssm/${each.key}"
  }
  parameters = {
    EnvVars         = "AWS_REGION=${var.aws_region} PREFIX=${local.prefix} SUFFIX=${local.suffix} REGION=${var.aws_region} DB_ENDPOINT=${aws_db_instance.cloudk3s.endpoint} K3S_NODEGROUP=${each.key} K3S_URL=https://${aws_lb.cloudk3s-private.dns_name}:6443"
    ShellScriptFile = "cloudk3s.sh"
    SourceInfo      = "{\"path\":\"https://s3.${var.aws_region}.amazonaws.com/${aws_s3_bucket.cloudk3s.id}/scripts/\"}"
    SourceType      = "S3"
  }
}
