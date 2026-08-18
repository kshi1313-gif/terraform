# ------------------------------------------------------------------
# provider.tf
# - Terraform 버전 / AWS Provider 버전을 고정(pin)해서
#   "내 컴퓨터에서는 되는데 다른 컴퓨터에서는 안 되는" 문제를 방지
# ------------------------------------------------------------------
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}
