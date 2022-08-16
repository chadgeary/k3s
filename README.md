# K3s Cluster on AWS
Deploys a scalable, private K3s cluster on AWS.

# Features
* offline
  * cluster has no internet access
  * lambda fetches external dependencies
* managed (RDS) DB for K3s backend
* interact with cluster via SSM
  * script included, see image below
  * works with kubectl, helm, lens, etc.

![Output](k3s.png)
