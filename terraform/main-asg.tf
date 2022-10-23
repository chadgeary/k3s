# launch template per node group
resource "aws_launch_template" "k3s" {
  for_each               = var.nodegroups
  name_prefix            = "${local.prefix}-${local.suffix}-${each.key}"
  vpc_security_group_ids = [aws_security_group.k3s-ec2.id]
  iam_instance_profile {
    arn = aws_iam_instance_profile.k3s-ec2.arn
  }
  ebs_optimized = true
  image_id      = data.aws_ami.k3s[each.value.ami].id
  block_device_mappings {
    device_name = data.aws_ami.k3s[each.value.ami].root_device_name
    ebs {
      volume_size           = each.value.volume.gb
      volume_type           = each.value.volume.type
      encrypted             = true
      kms_key_id            = aws_kms_key.k3s["ec2"].arn
      delete_on_termination = true
    }
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
}

# the autoscaling group
resource "aws_autoscaling_group" "k3s" {
  for_each    = var.nodegroups
  name_prefix = "${local.prefix}-${local.suffix}-${each.key}"
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.k3s[each.key].id
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
  target_group_arns         = each.key == "master" ? [aws_lb_target_group.k3s-private.arn] : []
  service_linked_role_arn   = aws_iam_service_linked_role.k3s.arn
  termination_policies      = ["ClosestToNextInstanceHour"]
  min_size                  = each.value.scaling_count.min
  max_size                  = each.value.scaling_count.max
  health_check_type         = "EC2"
  health_check_grace_period = "600"
  vpc_zone_identifier       = [for net in aws_subnet.k3s-private : net.id]

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

  depends_on = [aws_iam_user_policy_attachment.k3s-ec2-passrole, aws_s3_bucket_policy.k3s-private, aws_s3_bucket_policy.k3s-public, aws_cloudwatch_log_group.k3s-ec2, aws_s3_object.bootstrap, aws_iam_role_policy_attachment.k3s-ec2, aws_iam_role_policy_attachment.k3s-ec2-managed, aws_route53_zone.k3s, aws_route53_record.k3s-private, aws_lb.k3s-private, aws_vpc_endpoint_subnet_association.k3s-vpces, aws_db_instance.k3s]
}
