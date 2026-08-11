######################################
# 1. SG 생성 - (22/tcp, 80/tcp, 443/tcp)
# 2. keypair 생성
# 3. EC2 생성 - user_data
######################################

# 1. SG 생성 - (22/tcp, 80/tcp, 443/tcp)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "mySG" {
  name        = "mySG"
  description = "Allow SSH,WEB inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_22" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_80" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_443" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # 모든 포트 및 모든 트래픽 허용
}

# 2. keypair 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
# CMD: ssh-keygen -t rsa -N "" -f ~/.ssh/mykeypair
# CMD: cat ~/.ssh/mykeypair.pub  -> 퍼블릭 키 값 입력 정보 확인 / 정보값이 매우 방대
# file 함수 사용(권장)  -> 간단하게 키 값 입력 가능
resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/mykeypair.pub")
}

# 3. EC2 생성 - user_data
# * 새로 생성된 Subnet에 놓아야 한다 - subnet_id
# * 새로 만든 mykeypair 사용 - key_name
# * 새로 만든 mySG 사용 - vpc_security_group_ids
# * user_data -> user_data_replace_on_change (유저 데이터 변경시 EC2 새로 생성 및 기동)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "myEC2" {
  ami           = "ami-048f644e868baa0e8"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.myPubSN.id
  key_name = "mykeypair"
  vpc_security_group_ids = [aws_security_group.mySG.id]
  user_data_replace_on_change = true
  user_data = <<-EOF
    #!/bin/bash
    dnf -y install httpd mod_ssl
    echo "MyWEB" > /var/www/html/index.html
    systemctl enable --now httpd 
    EOF

  tags = {
    Name = "myEC2"
  }
}