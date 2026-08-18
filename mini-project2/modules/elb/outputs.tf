# modules/elb/outputs.tf

output "alb_dns_name" {
  description = "브라우저 접속용 ALB DNS 주소"
  value       = aws_lb.web_alb.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.web_tg.arn
}
