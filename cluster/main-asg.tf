# launch template per node group
resource "aws_launch_template" "cloudk3s" {
  for_each               = var.nodegroups
  name_prefix            = "${local.prefix}-${local.suffix}-${each.key}"
  vpc_security_group_ids = [aws_security_group.cloudk3s-ec2.id]
  iam_instance_profile {
    arn = aws_iam_instance_profile.cloudk3s-ec2.arn
  }
  ebs_optimized = true
  image_id      = data.aws_ami.cloudk3s[each.value.ami].id
  block_device_mappings {
    device_name = data.aws_ami.cloudk3s[each.value.ami].root_device_name
    ebs {
      volume_size           = each.value.volume.gb
      volume_type           = each.value.volume.type
      encrypted             = true
      kms_key_id            = aws_kms_key.cloudk3s["ec2"].arn
      delete_on_termination = true
    }
  }
}

# the autoscaling group
resource "aws_autoscaling_group" "cloudk3s" {
  for_each    = var.nodegroups
  name_prefix = "${local.prefix}-${local.suffix}-${each.key}"
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.cloudk3s[each.key].id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = toset(each.value.instance_types)
        content {
          instance_type     = override.key
          weighted_capacity = "1"
        }
      }
    }
  }
  target_group_arns         = [aws_lb_target_group.cloudk3s-private.arn]
  service_linked_role_arn   = aws_iam_service_linked_role.cloudk3s.arn
  termination_policies      = ["ClosestToNextInstanceHour"]
  min_size                  = each.value.scaling_count.min
  max_size                  = each.value.scaling_count.max
  health_check_type         = "EC2"
  health_check_grace_period = "600"
  vpc_zone_identifier       = [for net in aws_subnet.cloudk3s-private : net.id]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${local.prefix}-${local.suffix}"
    value               = "owned"
    propagate_at_launch = false
  }

  tag {
    key                 = "Name"
    value               = "${each.key}.${local.prefix}-${local.suffix}.internal"
    propagate_at_launch = true
  }

  depends_on = [aws_iam_user_policy_attachment.cloudk3s-ec2-passrole, aws_s3_bucket_policy.cloudk3s, aws_cloudwatch_log_group.cloudk3s-ec2, aws_s3_object.files, aws_iam_role_policy_attachment.cloudk3s-ec2, aws_iam_role_policy_attachment.cloudk3s-ec2-managed, aws_route53_zone.cloudk3s, aws_route53_record.cloudk3s-private, aws_lb.cloudk3s-private, aws_vpc_endpoint_subnet_association.cloudk3s-vpces]
}
