# generic
variable "prefix" {
  type        = string
  description = "Short, friendly, and alphanumeric for naming resources"
}

variable "suffix" {
  type        = string
  description = "Optional short, friendly, and alphanumeric for naming resources. If empty, a random 2 digit suffix is used."
  default     = ""
}

# aws
variable "profile" {
  type        = string
  description = "The aws profile to deploy the service"
}

variable "region" {
  type        = string
  description = "The aws region to deploy the service"
}

# amis
variable "amis" {
  type        = map(string)
  description = "AMI key:values for node groups to reference"
}

# urls
variable "urls" {
  type        = map(any)
  description = "Location K3s bin/tar are downloaded from via lambda"
}

# container images
variable "container_images" {
  type        = list(string)
  description = "Images to clone from public repositories to ECR"
}

# nodegroups (ec2 autoscaling groups)
variable "nodegroups" {
  type = map(object(
    {
      ami            = string,
      scaling_count  = map(any),
      volume         = map(any),
      instance_types = list(string)
    })
  )
  description = "Instance configuration"
}

# rds (k3s datastore)
variable "rds" {
  type = object({
    allocated_storage       = number
    backup_retention_period = number
    engine                  = string
    engine_version          = string
    instance_class          = string
    storage_type            = string
  })
}

# logs (cloudwatch)
variable "log_retention_in_days" {
  type        = number
  description = "cloudwatch log retention days"
}

# secrets
variable "secrets" {
  type        = map(any)
  description = "A map of secret strings stored encrypted in SSM. Readable by instances"
}

# vpc
variable "vpc_cidr" {
  type        = string
  description = "The network in CIDR notation used by AWS for VPC+Subnets"
}

variable "cluster_cidr" {
  type        = string
  description = "The network in CIDR notation used by k3s for pods and services"
}

variable "azs" {
  type        = number
  description = "The number of azs to use, min is 1 & max is number of azs in the region"
}

variable "nat_gateways" {
  type        = bool
  description = "Public internet access (outbound via nat_gateway(s))"
}

variable "vpc_endpoints" {
  type        = bool
  description = "Enable/disable private VPC endpoints for autoscaling, ecr, iam, etc."
}
