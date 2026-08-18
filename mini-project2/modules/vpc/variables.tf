# modules/vpc/variables.tf

variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  description = "새로 생성할 VPC의 CIDR 대역"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR 목록 (2개, 서로 다른 AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private Subnet CIDR 목록 (2개, 서로 다른 AZ)"
  type        = list(string)
}
