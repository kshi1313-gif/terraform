########################
# Provider 설정
########################
provider "aws" {
    region = "us-east-2"
}

########################
# Resource 설정
########################
# AMI ID 찾기
# Data Source: aws_ami
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
data "aws_ami" "amazonLinux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}

# SG 및 inbound/outbound rule 생성
# Resource: aws_security_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "mysg" {
  name        = "mysg"
  description = "Allow 22/tcp inbound traffic and all outbound traffic"

  tags = {
    Name = "mysg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/mykeypair.pub")
}

# EC2 생성
# Resource: aws_instance
# * https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "myInstance" {
  # AMI: Amazon 2023 AMI
  ami           = data.aws_ami.amazonLinux.id
  instance_type = "t3.micro"
  key_name = "mykeypair"
  vpc_security_group_ids = [aws_security_group.mysg.id]

  tags = {
    Name = "myInstance"
  }
}

output "ami_id" {
    value = aws_instance.myInstance.ami
    description = "Amazone Linux 2023 AMI ID"
}


output "ec2_public_ip" {
    value = "ssh ec2-user@${aws_instance.myInstance.public_ip}"
    description = "EC2 connection Public IP"
}