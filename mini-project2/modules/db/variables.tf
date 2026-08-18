# modules/db/variables.tf
# 이 모듈이 외부(루트)로부터 받아야 하는 값들

variable "project_name" {
  type = string
}

variable "db_ami_id" {
  type = string
}

variable "db_instance_type" {
  type = string
}

variable "private_subnet_ids" {
  description = "DB를 배치할 Private Subnet 목록 (count.index로 서로 다른 AZ에 배치)"
  type        = list(string)
}

variable "key_name" {
  type = string
}

variable "db_sg_id" {
  description = "루트에서 생성한 DB Security Group ID"
  type        = string
}

variable "db_root_password" {
  type      = string
  sensitive = true
}

variable "db_app_username" {
  description = "PHP 앱이 사용할 DB 계정명"
  type        = string
}

variable "db_app_password" {
  description = "PHP 앱이 사용할 DB 계정 비밀번호"
  type        = string
  sensitive   = true
}

variable "db_app_name" {
  description = "앱이 사용할 데이터베이스(스키마) 이름"
  type        = string
}
