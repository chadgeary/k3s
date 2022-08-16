# K3s Cluster on AWS
Deploys a scalable, private K3s cluster on AWS.

# Requirements
* aws account
* terraform v1+

# Deploy
```shell
# customize/edit settings.auto.tfvars

# init and apply
terraform init --upgrade
terraform apply
```

# Features
* offline
  * cluster has no direct internet access
  * saves costs on NAT gateways for development
  * lambda fetches external dependencies
  * optional tf for public access
    * replace `main-vpc.tf` with `main-vpc.tf-with-public`
* independently scalable
  * control-plane (masters)
  * agent (workers)
  * datastore (RDS postgres)
* interact with cluster via SSM PortForwardSession
  * script included, see image below
  * works with kubectl, helm, lens, etc.
* strongly enforced encryption
  * 6 independent kms keys (cloudwatch, ec2, lambda, rds, s3, ssm)
  * tailored kms key policies
  * tailored bucket policy / iam policies (ec2, lambda)

![Output](k3s.png)

[Contact Me](https://discord.gg/zmu6GVnPnj)