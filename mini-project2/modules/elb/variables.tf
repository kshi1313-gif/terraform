# modules/elb/variables.tf

variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

# EC2 모듈에서 넘어오는 값 (이게 이 모듈의 "EC2 의존성"을 만드는 핵심 변수)
variable "asg_id" {
  description = "ec2_web 모듈의 output(asg_id) - Target Group에 연결할 ASG 이름"
  type        = string
}
