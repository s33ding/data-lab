terraform {
  backend "s3" {
    bucket = "dataiesb-eks-cluster-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
