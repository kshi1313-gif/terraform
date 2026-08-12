# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0
# 다른 사람이 이미 구축한 인프라에 새로운 인프라를 추가할떄 사용
# 기존 인프라 구축했던 지점에 terraform.tfstate, | terraform.lock.hcl 파일을 원격으로 사용해서 인프라 추가 구성

data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../learn-terraform-data-sources-vpc/terraform.tfstate"
  }
}

provider "aws" {
  region = data.terraform_remote_state.vpc.outputs.aws_region
}

resource "random_string" "lb_id" {
  length  = 3
  special = false
}

module "elb_http" {
  source  = "terraform-aws-modules/elb/aws"
  version = "4.0.0"

  # Ensure load balancer name is unique
  name = "lb-${random_string.lb_id.result}-tutorial-example"

  internal = false

  security_groups = data.terraform_remote_state.vpc.outputs.app_security_group_ids
  subnets         = data.terraform_remote_state.vpc.outputs.public_subnet_ids

  number_of_instances = length(aws_instance.app)
  instances           = aws_instance.app.*.id

  listener = [{
    instance_port     = "80"
    instance_protocol = "HTTP"
    lb_port           = "80"
    lb_protocol       = "HTTP"
  }]

  health_check = {
    target              = "HTTP:80/index.html"
    interval            = 10
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
  }
}

data "aws_ami" "amazone2023ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.18-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

resource "aws_instance" "app" {
  ami = data.aws_ami.amazone2023ami.id
  instance_type = var.instance_type

  # sub[0], sub[1] <-- ec2-1[0], ec2-2[1], ec2-3[2], ec2-4[3]
  # ec2[#] % len(sub)
  subnet_id              = data.terraform_remote_state.vpc.outputs.private_subnet_ids[count.index % length(data.terraform_remote_state.vpc.outputs.private_subnet_ids)]
  vpc_security_group_ids = data.terraform_remote_state.vpc.outputs.app_security_group_ids

  count = var.instances_per_subnet * length(data.terraform_remote_state.vpc.outputs.private_subnet_ids)

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
    echo "<html><body><div>Hello, world!</div></body></html>" > /var/www/html/index.html
    EOF
}
