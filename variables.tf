# generic
variable "prefix" {
  type        = string
  description = "Short, friendly, and alphanumeric for naming resources"
}

# aws
variable "aws_profile" {
  type        = string
  description = "The aws profile to deploy the service"
}

variable "aws_region" {
  type        = string
  description = "The aws region to deploy the service"
}

# ami
variable "vendor_ami_name_string_arm64" {
  type        = string
  description = "The search string for the name of the ARM AMI from the AMI Vendor"
}

variable "vendor_ami_name_string_x86_64" {
  type        = string
  description = "The search string for the name of the x86 AMI from the AMI Vendor"
}


# urls
variable "urls" {
  type        = map(any)
  description = "Location K3s bin/tar are downloaded from via lambda"
}

# instances
variable "instances" {
  type = map(object(
    {
      scaling_count         = map(any),
      volume                = map(any),
      memory_mib            = map(any),
      vcpu_count            = map(any),
      burstable_performance = string
      local_storage         = string
      generations           = list(string)
    })
  )
  description = "Instance configuration"
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
  description = "The subnet in CIDR notation used for VPC/Subnets"
}

variable "azs" {
  type        = number
  description = "The number of azs to use, min is 1 & max is number of azs in the region"
}
