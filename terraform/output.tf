output "k3s" {
  value = <<EOT

# Images%{if data.aws_partition.k3s.partition == "aws"}
## public.ecr.aws
${data.aws_caller_identity.k3s.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.prefix}-${local.suffix}-ecr/<path>:<tag>
## quay.io
${data.aws_caller_identity.k3s.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.prefix}-${local.suffix}-quay/<path>:<tag>%{endif}
## var.container_images
%{for container in var.container_images}${data.aws_caller_identity.k3s.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.prefix}-${local.suffix}-codebuild/${container}
%{endfor}

# To fetch the kubeconfig from s3
# and open a tunnel to the k3s API
./connect.sh
EOT

}
