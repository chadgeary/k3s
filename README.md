# K3s Cluster on AWS
Deploys a scalable, private K3s cluster on AWS.

# Features
* offline
  * cluster has no internet access
  * lambda fetches external dependencies
  * optional tf for public access
    * replace `main-vpc.tf` with `main-vpc.tf-with-public`
* independently scalable
  * control-plane (masters)
  * agent (workers)
* interact with cluster via SSM
  * script included, see image below
  * works with kubectl, helm, lens, etc.
* managed (RDS) DB for K3s backend
* strongly enforced encryption & policies
  * kms key(s)
  * s3 bucket(s)
  * iam role(s)

![Output](k3s.png)

[Contact Me](https://discord.gg/zmu6GVnPnj)