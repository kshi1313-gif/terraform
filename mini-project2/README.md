# 실행 방법

## 사전 준비 (직접 해야 하는 것)

1) AWS 콘솔/CLI에서 키페어를 미리 생성 (기본값 이름: `mini2-key`)
```bash
aws ec2 create-key-pair --key-name mini2-key \
  --query 'KeyMaterial' --output text > mini2-key.pem
chmod 400 mini2-key.pem
```
- 다른 이름을 쓰고 싶으면 `-var="key_name=내키이름"`으로 덮어쓰면 됩니다.

2) DB 비밀번호를 관리자가 직접 정해서 넘겨줍니다 (필수 - default 없음)
```bash
terraform apply \
  -var="db_root_password=<강력한 root 비밀번호>" \
  -var="db_app_password=<강력한 app 계정 비밀번호>"
```
- 위처럼 -var로 안 넘기면 Terraform이 apply 실행 중 대화형으로 직접 물어봅니다.
- 반복 작업이 많다면 terraform.tfvars 파일을 만들어서 관리해도 됩니다
  (단, .gitignore에 반드시 추가해서 git에 올라가지 않게 할 것).

## 실행

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

## apply 완료 후 확인

```bash
terraform output alb_dns_name         # 배포된 사이트 접속 주소
terraform output db_master_private_ip # DB Master 프라이빗 IP (디버깅용)
```

- ALB Target Group Health Check가 통과할 때까지(약 1~2분) 기다린 후 브라우저로 접속하세요.
- **DB 연결 확인**: `http://<alb_dns_name>/` 접속 시 "DB 연결 성공" 문구와 MariaDB 버전이 보이면 EC2 -> DB 3306 통신이 정상입니다.
  (이전에는 index.php가 없어서 httpd 기본 테스트 페이지 "It works!"만 보였는데, 이제 실제 DB 커넥션 테스트 페이지로 교체됨)
- 안 뜨거나 "DB 연결 실패"가 보이면 아래 SSM 접속으로 직접 원인을 확인하세요.

## Private Subnet 인스턴스 직접 접속 (SSM Session Manager)

EC2/DB 모두 Private Subnet에 있어 SSH(키페어)로는 직접 접속이 안 됩니다.
대신 IAM Role에 `AmazonSSMManagedInstanceCore`가 붙어 있어 콘솔/CLI에서 바로 접속됩니다.

```bash
# 인스턴스 ID 확인
aws ec2 describe-instances --filters "Name=tag:Project,Values=mini2" \
  --query "Reservations[].Instances[].[InstanceId,Tags[?Key=='Name'].Value|[0]]" --output table

# 세션 시작
aws ssm start-session --target <instance-id>
```

접속 후 확인 예시:
```bash
# 웹서버 인스턴스에서
cat /var/www/html/db_config.php
curl -v telnet://<DB_HOST>:3306   # 포트 열려있는지 확인

# DB 인스턴스에서
sudo systemctl status mariadb
mysql -u root -p -e "SHOW DATABASES;"
mysql -u root -p -e "SELECT user, host FROM mysql.user;"  # app_user 생성됐는지 확인
```

## 리소스 정리

```bash
terraform destroy
```
