terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# aws configure list 출력 결과로 확인한다.
provider "aws" {
  region = "us-east-2"
  # cat ~/.aws/config
  shared_config_files = ["~/.aws/config"]
  # cat ~/.aws/credentials
  shared_credentials_files = ["~/.aws/credentials"]
  # aws configure list-profiles
  profile = "default"
}