# ------------------------------------------------------------------
# outputs.tf (루트)
# terraform apply 후 확인할 값들을 최상위로 노출
# ------------------------------------------------------------------

output "alb_dns_name" {
  description = "브라우저에서 접속할 ALB 주소"
  value       = module.elb.alb_dns_name
}

output "db_master_private_ip" {
  description = "DB Master 프라이빗 IP (디버깅용, 실제 접속은 EC2 통해서만 가능)"
  value       = module.db_cluster.db_master_private_ip
}

output "asg_id" {
  value = module.ec2_web.asg_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
