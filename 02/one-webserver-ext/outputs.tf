# EC2 Public IP만 뽑아서 출력
# curl http://$(terraform output -raw public_IP):8080   -raw: 큰따음표("")를 제거하고 출력
# * 해당 명령어 처럼 출력해서 나온 내용을 변수로 사용 가능
output "public_IP" {
    value = aws_instance.myinstance.public_ip
    description = "My EC2 Public IP" 
}
