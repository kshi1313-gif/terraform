# modules/ec2/variables.tf

variable "project_name" {
  type = string
}

variable "web_ami_id" {
  type = string
}

variable "web_instance_type" {
  type = string
}

variable "private_subnet_ids" {
  description = "EC2(WEB/WAS)를 배치할 Private Subnet ID 목록 (vpc 모듈 output)"
  type        = list(string)
}

variable "key_name" {
  type = string
}

variable "web_sg_id" {
  type = string
}

# DB 모듈에서 넘어오는 값 (이게 이 모듈의 "DB 의존성"을 만드는 핵심 변수)
variable "db_master_endpoint" {
  description = "DB Cluster 모듈의 output(db_master_private_ip)을 그대로 전달받음"
  type        = string
}

variable "db_app_username" {
  type = string
}

variable "db_app_password" {
  type      = string
  sensitive = true
}

variable "db_app_name" {
  type = string
}

variable "asg_min" {
  type = number
}

variable "asg_max" {
  type = number
}

variable "asg_desired" {
  type = number
}
