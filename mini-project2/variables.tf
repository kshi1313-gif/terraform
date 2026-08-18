# ------------------------------------------------------------------
# variables.tf (루트)
#
# [ 자격증명(키페어/DB 계정)은 "자동생성" 대신 "직접 입력"으로 되돌림 ]
# 이전 버전은 tls_private_key/random_password로 키·비밀번호를 자동
# 생성했지만, 그러면 관리자가 실제 비밀번호/개인키 값을 미리 알 수 없고
# (apply 후 output을 추출해야만 확인 가능), 팀 운영 관점에서
# "누가 어떤 값을 쓰는지"를 관리자가 통제하기 어렵다는 문제가 있었다.
#
# 그래서 아래 3개는 다시 "관리자가 직접 값을 정하는" 변수로 되돌린다.
#  - key_name        : AWS 콘솔/CLI에서 미리 만들어 둔 키페어 이름
#  - db_root_password: 관리자가 직접 정하는 MariaDB root 비밀번호
#  - db_app_username / db_app_password / db_app_name : 앱(PHP)이 사용할 계정
#
# db_root_password, db_app_password는 default를 주지 않았다(required).
# → terraform apply 시 -var로 값을 넘기지 않으면 Terraform이 CLI에서
#   직접 입력하라고 프롬프트를 띄운다. 즉 "관리자가 반드시 값을 알고
#   직접 입력하게" 강제하는 효과가 있다(tfvars를 쓰거나, -var로 넘겨도 됨).
#
# AMI ID는 민감정보가 아니라서 이전처럼 root main.tf의
# data "aws_ami"가 계속 자동 조회한다(그대로 유지).
# ------------------------------------------------------------------

variable "region" {
  description = "리소스를 생성할 AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "리소스 이름 접두사"
  type        = string
  default     = "mini2"
}

# --- VPC/Subnet (신규 생성) ---
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

# --- 키페어: 관리자가 AWS 콘솔/CLI에서 미리 생성해 둔 것을 사용 ---
variable "key_name" {
  description = "미리 생성해 둔 EC2 키페어 이름 (aws ec2 create-key-pair 등으로 사전 생성 필요)"
  type        = string
  default     = "mykeypair" # 콘솔에서 이 이름으로 키페어를 만들어 두면 별도 입력 없이 바로 사용 가능
}

# --- WEB/WAS(EC2) 관련 ---
# web_ami_id는 변수로 받지 않는다 -> main.tf의 data "aws_ami"가 자동 조회
variable "web_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "asg_min" {
  type    = number
  default = 2
}

variable "asg_max" {
  type    = number
  default = 4
}

variable "asg_desired" {
  type    = number
  default = 2
}

# --- DB 관련 ---
# db_ami_id도 마찬가지로 data "aws_ami"가 자동 조회
variable "db_instance_type" {
  type    = string
  default = "t3.micro"
}

# root 비밀번호 - default 없음(required) -> apply 시 관리자가 직접 입력/지정해야 함
variable "db_root_password" {
  description = "MariaDB root 비밀번호. 관리자가 직접 지정 (예: -var 또는 terraform.tfvars, 또는 apply 시 프롬프트 입력)"
  type        = string
  sensitive   = true
}

# 앱(PHP)이 사용할 DB 계정 - 이전 버전에는 PHP 코드에 하드코딩만 되어 있고
# 실제 DB에는 생성되지 않던 버그가 있었음. 아래 3개 변수로 명시적으로 관리.
variable "db_app_username" {
  description = "애플리케이션(PHP)이 사용할 DB 계정명"
  type        = string
  default     = "app_user"
}

variable "db_app_password" {
  description = "애플리케이션(PHP)이 사용할 DB 계정 비밀번호. 관리자가 직접 지정"
  type        = string
  sensitive   = true
}

variable "db_app_name" {
  description = "애플리케이션이 사용할 데이터베이스(스키마) 이름"
  type        = string
  default     = "appdb"
}
