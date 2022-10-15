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
    "description": "Ansible Playbooks via SSM",
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
    "PlaybookFile": {
      "type": "String",
      "description": "(Optional) The Playbook file to run (including relative path). If the main Playbook file is located in the ./automation directory, then specify automation/playbook.yml.",
      "default": "hello-world-playbook.yml",
      "allowedPattern": "[(a-z_A-Z0-9\\-)/]+(.yml|.yaml)$"
    },
    "ExtraVariables": {
      "type": "String",
      "description": "(Optional) Additional variables to pass to Ansible at runtime. Enter key/value pairs separated by a space. For example: color=red flavor=cherry",
      "default": "",
      "displayType": "textarea"
    },
    "Verbose": {
      "type": "String",
      "description": "(Optional) Set the verbosity level for logging Playbook executions. Specify -v for low verbosity, -vv or vvv for medium verbosity, and -vvvv for debug level.",
      "allowedValues": [
      "-v",
      "-vv",
      "-vvv",
      "-vvvv"
      ],
      "default": "-v"
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
      "name": "runShellScript",
      "inputs": {
      "runCommand": [
        "#!/bin/bash",
        "# Fetch ansible from s3",
        "aws --region ${var.aws_region} s3 sync s3://${local.prefix}-${local.suffix}/data/downloads/ ~/downloads/",
        "pip3 install --user --no-index --find-links ~/downloads/ansible ansible",
        "pip3 install --user --no-index --find-links ~/downloads/boto3 boto3",
        "pip3 install --user --no-index --find-links ~/downloads/botocore botocore",
        "echo \"Running Ansible in `pwd`\"",
        "for zip in $(find -iname '*.zip'); do",
        "  unzip -o $zip",
        "done",
        "PlaybookFile=\"{{PlaybookFile}}\"",
        "if [ ! -f  \"$${PlaybookFile}\" ] ; then",
        "   echo \"The specified Playbook file doesn't exist in the downloaded bundle. Please review the relative path and file name.\" >&2",
        "   exit 2",
        "fi",
        "export AWS_DEFAULT_REGION=${var.aws_region} && export AWS_REGION=${var.aws_region} && ~/.local/bin/ansible-playbook -i \"localhost,\" -c local -e \"{{ExtraVariables}}\" \"{{Verbose}}\" \"$${PlaybookFile}\""
      ]
      }
    }
    ]
  }
DOC
}

## association (playbook)
# master
resource "aws_ssm_association" "cloudk3s-master" {
  association_name = "${local.prefix}-${local.suffix}-master"
  name             = aws_ssm_document.cloudk3s.name
  targets {
    key    = "tag:Cluster"
    values = ["${local.prefix}-${local.suffix}-master"]
  }
  output_location {
    s3_bucket_name = aws_s3_bucket.cloudk3s.id
    s3_key_prefix  = "ssm"
  }
  parameters = {
    ExtraVariables = "PREFIX=${local.prefix} SUFFIX=${local.suffix} REGION=${var.aws_region} K3S_API_PORT=6443 DB_ENDPOINT=${aws_db_instance.cloudk3s.endpoint} K3S_ROLE=master K3S_URL=https://${aws_lb.cloudk3s-private.dns_name}:6443"
    PlaybookFile   = "cloudk3s.yaml"
    SourceInfo     = "{\"path\":\"https://s3.${var.aws_region}.amazonaws.com/${aws_s3_bucket.cloudk3s.id}/playbooks/cloudk3s/\"}"
    SourceType     = "S3"
    Verbose        = "-vvv"
  }
}

# worker
resource "aws_ssm_association" "cloudk3s-worker" {
  association_name = "${local.prefix}-${local.suffix}-worker"
  name             = aws_ssm_document.cloudk3s.name
  targets {
    key    = "tag:Cluster"
    values = ["${local.prefix}-${local.suffix}-worker"]
  }
  output_location {
    s3_bucket_name = aws_s3_bucket.cloudk3s.id
    s3_key_prefix  = "ssm"
  }
  parameters = {
    ExtraVariables = "PREFIX=${local.prefix} SUFFIX=${local.suffix} REGION=${var.aws_region} K3S_API_PORT=6443 DB_ENDPOINT=${aws_db_instance.cloudk3s.endpoint} K3S_ROLE=worker K3S_URL=https://${aws_lb.cloudk3s-private.dns_name}:6443"
    PlaybookFile   = "cloudk3s.yaml"
    SourceInfo     = "{\"path\":\"https://s3.${var.aws_region}.amazonaws.com/${aws_s3_bucket.cloudk3s.id}/playbooks/cloudk3s/\"}"
    SourceType     = "S3"
    Verbose        = "-vvv"
  }
}
