###################################
# 1. terraform/provider
# 2. EC2 Instance 생성(user_data(WEB:8080))
# * 1) SG(8080)
# * 2) EC2 생성
###################################

#
# 1. terraform/provider
#
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.25.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

#
# 2. resource - EC2 인스턴스 생성
#

# 1) SG 생성
resource "aws_security_group" "allow_8080" {
  name        = "allow_8080"
  description = "Allow 8080/tcp inbound traffic and all outbound traffic"

  tags = {
    Name = "allow_8080"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_web" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# 2) EC2 인스턴스 생성
resource "aws_instance" "myinstance" {
  ami           = "ami-0e5497a77ef21b5ac"
  instance_type = "t3.micro"

  vpc_security_group_ids = [ aws_security_group.allow_8080.id ]

  user_data_replace_on_change = true
  user_data = <<-EOF
  #!/bin/bash
  echo "<h1>My WEB</h1>" > index.html
  nohup busybox httpd -f -p 8080 &
  EOF

  tags = {
    Name = "myEC2"
  }
}