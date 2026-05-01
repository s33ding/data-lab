variable "cluster_name" {
  type    = string
  default = "dataiesb-cluster"
}

variable "vpc_id" {
  type    = string
  default = "vpc-08f71cff199dc1fc6"
}

variable "subnet_ids" {
  type = list(string)
  default = [
    "subnet-0a8fdc075bd605e6a", # Public Subnet 1 - us-east-1a
    "subnet-0c75a251de3ba1adf", # Public Subnet 2 - us-east-1b
  ]
}
