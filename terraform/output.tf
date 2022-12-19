output "k3s" {
  value = <<EOT

# Images%{if data.aws_partition.k3s.partition == "aws"}
## public.ecr.aws
${data.aws_caller_identity.k3s.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.prefix}-${local.suffix}-ecr/<path>:<tag>
## quay.io
${data.aws_caller_identity.k3s.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.prefix}-${local.suffix}-quay/<path>:<tag>%{endif}
## var.container_images
%{for container in var.container_images["arm64"]}${data.aws_caller_identity.k3s.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.prefix}-${local.suffix}-codebuild/arm64/${container}
%{endfor}%{for container in var.container_images["x86_64"]}${data.aws_caller_identity.k3s.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.prefix}-${local.suffix}-codebuild/x86_64/${container}
%{endfor}
# To fetch the kubeconfig from s3
# and open a tunnel to the k3s cluster
./connect.sh

# To cleanup ECR repositories
repos=$(aws ecr describe-repositories --query "repositories[?starts_with(repositoryName, '${local.prefix}-${local.suffix}')].repositoryName" --output text)
for repo in $repos; do
  aws ecr delete-repository --repository-name $repo --force
done
EOT

}
