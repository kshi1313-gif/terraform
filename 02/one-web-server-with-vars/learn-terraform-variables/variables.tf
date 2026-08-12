# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Variable declarations
variable "aws_region" {
  default     = "us-east-2"
  type        = string
  description = "Aws Region"
}

variable "vpc_cidr_block" {
  default     = "10.0.0.0/16"
  type        = string
  description = "AWS Vpc Cidr Block"
}

variable "instance_count" {
  default     = 2
  type        = number
  description = "EC2 Instace Count"
}

variable "disable_vpn_gateway" {
  default     = false
  type        = bool
  description = "Enable_Vpn_gateway"
}

# variable "public_subnet" {
#   default = ["10.0.1.0/24", "10.0.2.0/24"]
#   type = list(string)
#   description = "Public Subnets"
# }

variable "public_subnet_cidr_blocks" {
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24",
    "10.0.7.0/24",
    "10.0.8.0/24",
  ]
  type        = list(string)
  description = "Public Subnet CIDR Blocks"
}

variable "subnet_count" {
  default     = 2
  type        = number
  description = "Public Subnet Count"
}

variable "private_subnet_cidr_blocks" {
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24",
    "10.0.104.0/24",
    "10.0.105.0/24",
    "10.0.106.0/24",
    "10.0.107.0/24",
    "10.0.108.0/24",
  ]
  type        = list(string)
  description = "Private Subnet CIDR Blocks"
}

variable "resource_tag" {
  default = {
    project     = "project-alpha",
    environment = "dev"
  }
  type        = map(string)
  description = "Resources Tags"
}

variable "ec2_instance_type" {
  type        = string
  description = "EC2 Instance Type(ex: t2.micro):"
}
# defalut값이 없을 경우 
# -> 1. apply 실행 시 입력값 수동으로 입력
# -> 2. export TF_VAR_ec2_instance_type=""
# -> 3. vi terraform.tfvars 파일 생성 후 입력값 저장