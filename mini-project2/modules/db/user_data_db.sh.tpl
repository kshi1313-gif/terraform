#!/bin/bash
# ------------------------------------------------------------------
# DB(EC2) 부팅 시 자동 실행되는 스크립트
# role 변수: "master" 또는 "replica" (아래 main.tf에서 templatefile로 주입)
# ------------------------------------------------------------------
set -e

# 1) MariaDB 설치
dnf install -y mariadb105-server
systemctl enable --now mariadb

# 2) root 비밀번호 설정 (실습용 - 실제 운영에서는 Secrets Manager 등으로 관리)
mysqladmin -u root password '${db_root_password}'

# 3) 외부(웹서버)에서 접속 가능하도록 bind-address 수정
sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/my.cnf.d/mariadb-server.cnf || true

# 4) role이 master인 경우, 앱(PHP)이 사용할 DB/계정을 생성
#    (실제 replica 연결 시 이 DB/계정은 복제를 통해 자동 전파됨 -
#     단, 복제 설정 자체는 아래처럼 골격만 있고 별도 구성이 필요함)
if [ "${role}" = "master" ]; then
  mysql -u root -p'${db_root_password}' <<'SQL'
CREATE DATABASE IF NOT EXISTS `${db_app_name}`;
CREATE USER IF NOT EXISTS '${db_app_username}'@'%' IDENTIFIED BY '${db_app_password}';
GRANT ALL PRIVILEGES ON `${db_app_name}`.* TO '${db_app_username}'@'%';
FLUSH PRIVILEGES;
SQL

  echo "[master] server-id, log-bin, GTID 옵션은 /etc/my.cnf.d/ 에 별도 설정 필요"
fi

systemctl restart mariadb
