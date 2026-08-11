#######################################
# 1. provider 설정
# 2. VPC 생성
# 3. IGW 생성 및 연결
# 4. PubSN 생성
# 5. PubSN-RT 생성 및 연결
#######################################

# 1. provider 설정
provider "aws" {
  region = "us-east-2"
}

# 2. VPC(IGW) 생성 - PubSubnet(PubRT)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
# * DNS 호스트 이름 활성화
resource "aws_vpc" "myVPC" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC"
  }
}

# 3. IGW 생성 및 VPC 연결
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}

# 4. PubSN 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
# * 퍼블릭 IPv4 주소 자동 할당 활성화 
resource "aws_subnet" "myPubSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "myPubSN"
  }
}

# 5. PubSN-RT 생성 및 설정, 연결
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# -> 라우팅 테이블 생성
# * default route -> myIGW
resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubRT"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
# -> 라우팅 테이블 연결
# * myPubRT에 연결
resource "aws_route_table_association" "myPubRTassoc" {
  subnet_id      = aws_subnet.myPubSN.id
  route_table_id = aws_route_table.myPubRT.id
}