#!/bin/bash
mkdir -p /var/log/redis /var/lib/redis/sentinel

cat > /etc/redis/sentinel.conf <<'EOF'
# 基础配置
port 26379
bind 0.0.0.0
daemonize no
protected-mode no
logfile "/var/log/redis/sentinel-136.log"
dir "/var/lib/redis/sentinel"

# 监控主节点
sentinel monitor mymaster 192.168.189.135 6379 2

# 认证
sentinel auth-pass mymaster yjk19308769931

# 故障判定与切换
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
EOF

chown -R redis:redis /var/log/redis /var/lib/redis/sentinel
chmod 750 /var/log/redis /var/lib/redis/sentinel

firewall-cmd --permanent --add-port=26379/tcp
firewall-cmd --permanent --add-port=26934/tcp
firewall-cmd --reload

systemctl restart redis-sentinel
systemctl enable redis-sentinel
systemctl status redis-sentinel

