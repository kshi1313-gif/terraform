# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Output declarations
# vpc_id:
output "vpc_id" {
  value = module.vpc.vpc_id
  description = "New VPC ID"
}

# LB DNS name:
output "lb_dns" {
  value = "http://${module.elb_http.elb_dns_name}/"
  description = "LB DNS Name"
}

# EC2 Instance Count:
output "ec2_count" {
  value = length(module.ec2_instances.instance_ids)
  description = "EC2 Instance Count"
}

# DB username
output "db_username" {
  value = aws_db_instance.database.username
  description = "DB Username"
  sensitive = true
}

# DB password
output "db_password" {
  value = aws_db_instance.database.password
  description = "DB Password"
  sensitive = true
}