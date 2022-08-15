# launch template for asg
resource "aws_launch_template" "cloudk3s" {
  name_prefix            = "${local.prefix}-${local.suffix}"
  vpc_security_group_ids = [aws_security_group.cloudk3s-ec2.id]
  iam_instance_profile {
    arn = aws_iam_instance_profile.cloudk3s-ec2.arn
  }
  ebs_optimized = true
  image_id      = data.aws_ami.cloudk3s.id
  # instance_requirements {
  #   burstable_performance = var.instances.burstable_performance
  #   local_storage         = var.instances.local_storage
  #   instance_generations  = var.instances.generations
  #   memory_mib {
  #     min = var.instances.memory_mib.min
  #     max = var.instances.memory_mib.max
  #   }
  #   vcpu_count {
  #     min = var.instances.vcpu_count.min
  #     max = var.instances.vcpu_count.max
  #   }
  # }
  block_device_mappings {
    device_name = data.aws_ami.cloudk3s.root_device_name
    ebs {
      volume_size           = tonumber(var.instances.volume.gb)
      volume_type           = var.instances.volume.type
      encrypted             = true
      kms_key_id            = aws_kms_key.cloudk3s["ec2"].arn
      delete_on_termination = true
    }
  }
  lifecycle {
    ignore_changes = [
      image_id
    ]
  }
}

# the autoscaling group
resource "aws_autoscaling_group" "cloudk3s" {
  name_prefix = "${local.prefix}-${local.suffix}"
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.cloudk3s.id
        version            = "$Latest"
      }
      override {
        instance_requirements {
          burstable_performance = var.instances.burstable_performance
          local_storage         = var.instances.local_storage
          instance_generations  = var.instances.generations
          memory_mib {
            min = var.instances.memory_mib.min
            max = var.instances.memory_mib.max
          }
          vcpu_count {
            min = var.instances.vcpu_count.min
            max = var.instances.vcpu_count.max
          }
        }
      }
    }
  }
  target_group_arns         = [aws_lb_target_group.cloudk3s-private.arn]
  service_linked_role_arn   = aws_iam_service_linked_role.cloudk3s.arn
  termination_policies      = ["ClosestToNextInstanceHour"]
  min_size                  = tonumber(var.instances.scaling_count.min)
  max_size                  = tonumber(var.instances.scaling_count.max)
  health_check_type         = "EC2"
  health_check_grace_period = "600"
  vpc_zone_identifier       = [for net in aws_subnet.cloudk3s-private : net.id]

  lifecycle {
    create_before_destroy = true
  }

  dynamic "tag" {
    for_each = local.cloudk3s-tags
    content {
      key                 = tag.value.key
      value               = tag.value.value
      propagate_at_launch = tag.value.propagate_at_launch
    }
  }

  depends_on = [aws_iam_user_policy_attachment.cloudk3s-ec2-passrole, aws_s3_bucket_policy.cloudk3s, aws_cloudwatch_log_group.cloudk3s, aws_s3_object.files, aws_iam_role_policy_attachment.cloudk3s-ec2, aws_iam_role_policy_attachment.cloudk3s-ec2-managed, aws_route53_zone.cloudk3s, aws_route53_record.cloudk3s-private, aws_lb.cloudk3s-private]
}
