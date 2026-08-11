######################################
# 1. NAT Gateway 생성 -> PublicSN 위치에 생성
# 2. Private Subnet 생성
# 3. Private Routing Table 생성 및 연결
# 4. SG 그룹 생성
# 5. EC2 생성
######################################

# 1. NAT Gateway 생성 -> PublicSN 위치에 생성
# * Elastic IP 생성 -> 탄력적 IP 생성
# * Public Subnet에 NAT Gateway 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
# -> EIP (탄력적 IP) 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
# -> NAT Gateway 생성
resource "aws_eip" "myEIP" {
  domain = "vpc"
  #depends_on                = [aws_internet_gateway.gw]

  tags = {
    Name = "myEIP"
  }
}

resource "aws_nat_gateway" "myNAT-GW" {
  allocation_id = aws_eip.myEIP.id
  subnet_id     = aws_subnet.myPubSN.id

  tags = {
    Name = "myNAT-GW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.myIGW]
}

# 2. Private Subnet 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
# * 새로 생성된 myVPC에 생성
resource "aws_subnet" "myPriSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "myPriSN"
  }
}

# 3. Private Routing Table 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "myPriRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/24"
    gateway_id = aws_nat_gateway.myNAT-GW.id
  }

  tags = {
    Name = "myPriRT"
  }
}

# 3-1. Private Routing Table 연결
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "myPriRTassoc" {
  subnet_id      = aws_subnet.myPriSN.id
  route_table_id = aws_route_table.myPriRT.id
}

# 4. SG 그룹 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
# * SG - 22/tcp, 80/tcp, 443/tcp
resource "aws_security_group" "mySG-1" {
  name        = "mySG-1"
  description = "Allow SSH,WEB inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG-1"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_22_2" {
  security_group_id = aws_security_group.mySG-1.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_80_2" {
  security_group_id = aws_security_group.mySG-1.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_443_2" {
  security_group_id = aws_security_group.mySG-1.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_2" {
  security_group_id = aws_security_group.mySG-1.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# 5. EC2 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
# * 새로 생성된 SG 사용
# * mykeypair 등록
# * 새로 생성된 myPriSN에 생성
# * user_data -> user_data_replace_on_change 생성
resource "aws_instance" "myEC2-1" {
  ami           = "ami-048f644e868baa0e8"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.mySG.id]
  subnet_id = aws_subnet.myPriSN.id
  user_data_replace_on_change = true
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd mod_ssl
    echo "My Web Server 2 Test Page" > /var/www/html/index.html
    systemctl enable --now httpd

    cat <<'KEY' >> /home/ec2-user/.ssh/mykeypair.key
    ${file("~/.ssh/mykeypair")}
    KEY
    chmod 600 /home/ec2-user/.ssh/mykeypair.key
    EOF

  tags = {
    Name = "myEC2-1"
  }
}