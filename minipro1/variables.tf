variable "vpc_tag" {
  default = {
    Name = "myVPC"
  }
}

variable "igw_tag" {
  default = {
    Name = "myIGW"
  }
}

variable "pubsn_tag" {
  default = {
    Name = "myPubSN"
  }
}

variable "pubrt_tag" {
  default = {
    Name = "myPubRT"
  }
}

variable "ec2_sg_name" {
  default = "myEC2_SG"
}

locals {
  ec2_sg_tag = {
    Name = var.ec2_sg_name
  }
}

variable "ec2_tag" {
  default = {
    Name = "myEC2"
  }
}