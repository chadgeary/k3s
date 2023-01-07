resource "aws_efs_file_system" "k3s" {
  creation_token   = "${local.prefix}-${local.suffix}"
  encrypted        = "true"
  kms_key_id       = aws_kms_key.k3s["efs"].arn
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_efs_file_system_policy" "k3s" {
  file_system_id                     = aws_efs_file_system.k3s.id
  bypass_policy_lockout_safety_check = "false"
  policy                             = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "efs",
    "Statement": [
        {
            "Sid": "Mount",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Resource": "${aws_efs_file_system.k3s.arn}",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "true"
                }
            }
        },
        {
            "Sid": "Caller",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${data.aws_caller_identity.k3s.arn}"
            },
            "Resource": "${aws_efs_file_system.k3s.arn}",
            "Action": [
                "elasticfilesystem:*"
            ]
        },
        {
            "Sid": "DriverControlPlane",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_role.k3s-ec2-controlplane.arn}"
            },
            "Resource": "${aws_efs_file_system.k3s.arn}",
            "Action": [
                "elasticfilesystem:CreateAccessPoint",
                "elasticfilesystem:DeleteAccessPoint"
            ]
        }
    ]
}
POLICY
}

resource "aws_efs_mount_target" "k3s" {
  for_each        = local.private_nets
  file_system_id  = aws_efs_file_system.k3s.id
  subnet_id       = aws_subnet.k3s-private[each.key].id
  security_groups = [aws_security_group.k3s-efs.id]
}
