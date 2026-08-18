# modules/db/outputs.tf
# 이 모듈 밖(루트, 다른 모듈)에서 참조할 수 있는 값들

output "db_instance_ids" {
  value = aws_instance.db[*].id
}

output "db_private_ips" {
  description = "DB 인스턴스 2대의 프라이빗 IP 전체 목록"
  value       = aws_instance.db[*].private_ip
}

# ec2_web 모듈이 실제로 참조할 값 -> 이게 있어야 ec2 모듈이 실행됨
output "db_master_private_ip" {
  description = "Master DB(index 0)의 프라이빗 IP - WEB/WAS에서 이 주소로 접속"
  value       = aws_instance.db[0].private_ip
}
