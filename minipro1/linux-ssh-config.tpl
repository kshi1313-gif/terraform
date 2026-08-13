# $HOME/.ssh/config 파일 생성
cat << EOF >> ~/.ssh/config

Host ${hostname}
    HostName ${hostname}
    User ${user}
    IdentityFile ${identityfile}
EOF

# $HOME/.ssh/config 파일 퍼미션 설정
chmod 600 ~/.ssh/config