variable "myregion" {
  default = "us-east-2"
}

variable "myLBname" {
  default = "myLB_SG"
}

variable "myLB_TG_port" {
  default = 80
}

variable "myLB_Listener_port" {
  default = 80
}

variable "myASGname" {
  default = "myASG_SG"
}

locals {
  myLB_SG_tag = {
    Name = "${var.myLBname}"
  }
  myASG_SG_tag = {
    Name = "${var.myASGname}"
  }
}
