# ------------------------------------------------------------------
# modules/vpc/main.tf
# 자료의 "net module"에 해당 (VPC 생성, IGW 생성 및 연결,
# Public/Private Subnet 생성, Routing Table 생성 및 연결)
#
# 요구 조건 반영:
# - 새로운 VPC 1개
# - Public Subnet x 2 (서로 다른 AZ) -> ALB, NAT Gateway 배치
# - Private Subnet x 2 (서로 다른 AZ) -> EC2(WEB/WAS), DB 배치
# ------------------------------------------------------------------

# 배포 리전에서 사용 가능한 AZ 목록을 가져와서 앞 2개만 사용
# -> 하드코딩(ap-northeast-2a/2c) 대신 리전이 바뀌어도 동작하도록 함
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# --- Public Subnet x 2 ---
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # ALB, NAT GW가 위치할 서브넷이므로 public IP 자동 할당

  tags = { Name = "${var.project_name}-public-${count.index + 1}" }
}

# --- Private Subnet x 2 ---
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "${var.project_name}-private-${count.index + 1}" }
}

# --- NAT Gateway (Private Subnet의 EC2/DB가 yum install 등 외부 통신할 때 필요) ---
# 실습/비용 절감 목적이면 NAT Gateway 1개만 생성(둘 중 하나의 Public Subnet에 배치)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # 0번 Public Subnet에 배치
  tags          = { Name = "${var.project_name}-nat-gw" }

  depends_on = [aws_internet_gateway.igw]
}

# --- Public Route Table: 0.0.0.0/0 -> IGW ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Private Route Table: 0.0.0.0/0 -> NAT Gateway ---
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
