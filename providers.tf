terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    polaris = {
      source  = "rubrikinc/polaris"
      version = "~>1.1.1"
    }
  }
}
