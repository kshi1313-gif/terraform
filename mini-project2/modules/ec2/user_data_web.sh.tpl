#!/bin/bash
# ------------------------------------------------------------------
# WEB/WAS(EC2) 부팅 시 자동 실행 스크립트
# httpd + php 설치, DB 접속 정보를 PHP 설정 파일에 주입
# ${db_host} 는 아래 main.tf의 templatefile()에서 DB master IP로 치환됨
# ------------------------------------------------------------------
set -e

# 1) httpd, php 설치
dnf install -y httpd php php-mysqlnd
systemctl enable --now httpd

# 2) DB 접속 정보를 PHP 설정 파일로 생성
#    -> Terraform이 만든 DB 모듈의 output이 여기 실제로 쓰인다는 게 핵심
cat > /var/www/html/db_config.php << 'EOF'
<?php
  $DB_HOST = "${db_host}";
  $DB_USER = "${db_username}";
  $DB_PASS = "${db_password}";
  $DB_NAME = "${db_name}";
  // 실제 운영에서는 이 파일 대신 SSM Parameter Store/Secrets Manager 사용 권장
  // (지금은 학습용으로 Terraform이 값을 그대로 주입)
?>
EOF

# 3) DB 연결을 실제로 테스트하는 페이지 생성
#    httpd 기본 설치 시 딸려오는 "It works!" 테스트 페이지는 삭제한다.
#    (그게 남아있으면 index.html이 index.php보다 우선순위가 높아서
#     아래 index.php가 만들어져도 계속 "It works!"만 보이게 된다)
rm -f /var/www/html/index.html

cat > /var/www/html/index.php << 'EOF'
<?php
  require '/var/www/html/db_config.php';

  $mysqli = @new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME);

  echo "<h2>3-Tier Mini Project 2</h2>";
  echo "<p>인스턴스 호스트명: " . gethostname() . "</p>";

  if ($mysqli->connect_errno) {
    echo "<p style='color:red'>DB 연결 실패: " . htmlspecialchars($mysqli->connect_error) . "</p>";
  } else {
    echo "<p style='color:green'>DB 연결 성공 (host: " . htmlspecialchars($DB_HOST) . ", db: " . htmlspecialchars($DB_NAME) . ")</p>";
    $result = $mysqli->query("SELECT VERSION() AS v");
    if ($result) {
      $row = $result->fetch_assoc();
      echo "<p>MariaDB 버전: " . htmlspecialchars($row['v']) . "</p>";
    }
    $mysqli->close();
  }
?>
EOF

# 4) 헬스체크용 페이지 (ALB Target Group health check가 이 경로를 확인)
#    -> DB 연결 여부와 무관하게 웹서버 자체의 생존만 확인하는 용도라 별도로 둔다
echo "OK" > /var/www/html/healthcheck.html

systemctl restart httpd
