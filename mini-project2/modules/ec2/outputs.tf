# modules/ec2/outputs.tf

# elb 모듈이 실제로 참조할 값 -> 이게 있어야 elb 모듈이 실행됨
output "asg_id" {
  description = "ELB 모듈에서 Target Group에 연결(attachment)할 ASG 이름"
  value       = aws_autoscaling_group.web.name
}
