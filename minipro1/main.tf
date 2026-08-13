# 최종 목표
# VPC(IGW) + Public Subnet(RT) + EC2(docker)
#
# 1. VPC 생성
# * IGW 생성과 VPC에 연결
# 2.Public Subnet 생성
# * PubSN 생성
# * PubRT 생성과 PubSN 연결 후 Default Route 설정
# 3.EC2 생성
# * EC2 생성
#   - user_data(docker 설치)

# 1. VPC 생성
# 1) VPC 생성
# * enable_dns_hostname
# * cidr block: 10.0.0.0/16
resource "aws_vpc" "myVPC" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags                 = var.vpc_tag
}

# 2) IGW 생성과 VPC에 연결
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id
  tags   = var.igw_tag
}
# 2.Public Subnet 생성
# 1) PubSN 생성
# * 퍼블릭 IPv4 주소 자동 할당
resource "aws_subnet" "myPubSN" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags                    = var.pubsn_tag
}
# 2) PubRT 생성과 PubSN 연결 후 Default Route 설정
resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id
  tags   = var.pubrt_tag

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }
}

resource "aws_route_table_association" "myPubRTassoc" {
  subnet_id      = aws_subnet.myPubSN.id
  route_table_id = aws_route_table.myPubRT.id
}

# 3.EC2 생성
#  1) SG(all port)
resource "aws_security_group" "myEC2_SG" {
  name        = var.ec2_sg_name
  description = "Allow 80/tcp, 443/tcp inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id
  tags        = local.ec2_sg_tag
}

resource "aws_vpc_security_group_ingress_rule" "ALL" {
  security_group_id = aws_security_group.myEC2_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

}

resource "aws_vpc_security_group_egress_rule" "ALL" {
  security_group_id = aws_security_group.myEC2_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
#  2) KeyPair
resource "aws_key_pair" "myKeypair" {
  key_name   = "myKeypair"
  public_key = file("~/.ssh/mykeypair.pub")
}

#  3) EC2 생성
#    - data_source - aws_ami
#    - user_data(docker 설치)
data "aws_ami" "amz2023ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.18-x86*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

# subnet
# mykeypair
# Sequrity Group
# user_data
resource "aws_instance" "myEC2" {
  ami                         = data.aws_ami.amz2023ami.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.myPubSN.id
  key_name                    = "myKeypair"
  vpc_security_group_ids      = [aws_security_group.myEC2_SG.id]
  user_data_replace_on_change = true
  user_data                   = filebase64("user_data.sh")
  tags                        = var.ec2_tag

provisioner "local-exec" {
  command        = templatefile("linux-ssh-config.tpl", {
    hostname     = self.public_ip,
    user         = "ec2-user",
    identityfile = "~/.ssh/mykeypair"
  })
  interpreter    = ["bash", "-c"]
}
}