# K3s Cluster on AWS
Deploys a low-cost, scalable, private K3s cluster on AWS.

## Requirements
* aws account, [awscli v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), [ssm plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-linux)
* terraform v1+

## Deploy
```shell
# customize/edit settings.auto.tfvars

# init and apply
terraform init --upgrade
terraform apply
```

## Features
* offline
  * cluster functions without direct internet access
    * enable egress w/ `var.nat_gateways = true`
    * enable ingress w/ `var.public_lb = true`
      * example use: `terraform/manifests/nginx.yaml`
  * container images available via (see tf output):
    * ecr pull through for [public-ecr](https://gallery.ecr.aws/docker) and [quay.io](https://quay.io/search)
    * codebuild => ecr mirroring (`var.container_images`)
  * lambda+ssm manage k3s' [airgap](https://docs.k3s.io/installation/airgap) installation
* multiple scaling configurations
  * create any number of node groups
  * define the following components per node group, including the control-plane
    * node count (min/max)
    * instance type
    * architecture (arm, x86, gpu)
    * local storage
  * datastore (RDS postgres)
  * availability zones
* IRSA (IAM roles for Service Accounts) support
  * OIDC endpoint enrollment via s3 bucket static page
  * lambda managed aws identity provider
  * example: `terraform/manifests/irsa.yaml` after apply
* interact with cluster API via SSM PortForwardSession
  * script included, see example image
  * works with kubectl, helm, k9s, lens, etc.
* strongly enforced encryption + access management
  * 7 independent kms keys (codebuild, cloudwatch, ec2, lambda, rds, s3, ssm)
  * tailored kms key, bucket, iam, and trust policies

![Output](k3s.png)

[Contact Me](https://discord.gg/sB9dUaj9jt)
