#!/bin/bash

# 1. 准备日志与数据目录
mkdir -p /var/log/redis /var/lib/redis/slave2
touch /var/log/redis/redis-slave2.log

# 2. redis 用户不存在才创建，已存在则跳过
id redis &>/dev/null || useradd -r -s /sbin/nologin redis

# 3. 生成从库配置（heredoc 加引号，注释单独成行，无行尾注释）
cat > /etc/redis/redis.conf <<'EOF'
# 基础配置
port 6379
bind 0.0.0.0
daemonize no
logfile "/var/log/redis/redis-slave2.log"
dir "/var/lib/redis/slave2"

# 核心复制配置
replicaof 192.168.189.135 6379
replica-read-only yes
# 主库若设了 requirepass，取消下一行注释并填成主库密码
# masterauth <主库密码>
EOF

# 4. 授权
chown -R redis:redis /var/log/redis /var/lib/redis/slave2
chmod 750 /var/log/redis /var/lib/redis/slave2

# 5. 重启并设开机自启
systemctl daemon-reload
systemctl restart redis
systemctl enable redis
systemctl status redis

