                                                         Redis一主三从主从复制与哨兵模式自动选主
    1.背景与主要概念： 这里还是看c站技术博主的文档吧        https://blog.csdn.net/weixin_29197835/article/details/170513896?ops_request_misc=&request_id=&biz_i





    2.环境规划：
     192.168.189.1     Redis master
     192.168.189.2     Redis slave 1
     192.168.189.3     Redis slave 2
     192.168.189.4     Redis slave 3
  




    3.关于Redis一主三从主从复制的安装部署与配置(Linux系统发行版为centos7)
    3（1). 先确认centos版本 cat /etc/os-release yum repolist enabled
           安装epel和remi relaease-7  yum install -y epel-release  yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
           配置Redis7.0镜像源， touch /etc/yum.repos.d/redis.repo 直接创建放置Redis镜像源配置文件的内容的report文件,cat redis.repo 
            ，然后vim编辑这个镜像源文件，[Redis]     name=Redis   baseurl=http://packages.redis.io/rpm/rockylinux9   enabled=1    gpgcheck=1
         从Redis官方哪里下载GPG秘钥 curl -fsSL https://packages.redis.io/gpg > /tmp/redis.key，然后把公钥导入rpm数据库 rpm --import /tmp/redis.key，
          yum安装Redis7.0的rpm包，yum -y install redis, 
           验证Redis版本和启动 redis-server --version  systemctl enable --now redis   systemctl status redis   redis-cli ping 回复版本和PONG就是完成，四台机器都要这样一遍，不能漏


    3（2）Redis master 的配置部署 ping -c3 节点IP，测试连通性， cd /etc/redis 进入Redis的配置目录中  > 清空redis.conf里的内容，写入我上放给的配置保存退出即可，然后根据配置
    内容中的log和dir所指向的log文件和目录，，有就直接下一步，没有就从头建立目录文件，然后创立Redis这个用户，尽量保证安全性，chown -R redis:redis log的目录 和data的目录
    然后就systemctl daemon-reload ,systemctl restart redis,systemctl enable redis,systemctl status redsi ,出现active即可。然后放行6379端口，firewall-cmd --permanent --add-port=6379/tcp  firewall-cmd --reload 和 关闭安全机制 setenfoirce 0

  
    
    3（3）另外三个salve节点和上方的master一样，只是主要配置文件里面的内容有些不一样，比如说指向master节点，上方有节点的配置内容直接复制即可，注意放开端口和安全机制但是我没放开安全机制也能顺利关联到看着办吧
    
    
    
    
    3（4）这里主节点连接测试slave节点用  redis-cli -h slave节点  -p 6379 ,每个节点都测试，查看slave状态和数量 用redis-cli -a 配置文件中的密码 INFO replication | grep slave，
    如果都显示数量，节点IP和端口和状态为online，这样一主三从主从复制就完成了，当然也可以看单个节点的状态和细节 redis-cli -h 节点IP -p 6379 -a 配置文件密码 INFO 
    replication，最后在master测试  redis-cli -h master节点IP -p 6379 -a 配置文件密码 SET replication_test "我们都是彭于晏" ，登录随意一台slave节点 redis-cli -h 
    slave节点IP -p 6379 -a 配置文件密码 GET replication_test 返回我们都是彭于晏 即为测试成功







    4（1）上面主从复制如果主节点宕机了，需要手动切换从节点变成新的主节点，宕机的主节点恢复之后变成slave从节点，需要手动切换效率很低且还麻烦了些，直接接入哨兵，
          启用哨兵模式，master宕机投票自动轩主，实现Redis自动化，我这里给三个slave节点设置对应的都设置了哨兵，因为哨兵集群判定主库下线、选 leader、发起故障转移，都要**            超过半数哨兵投票同意**（majority，过半才算数）。这是为了：不能只有一个哨兵说主库挂了就切换，避免误判。投票时不能出现两边票数一样、谁也说服不了谁。，
          vim /etc/redis/sentinel.conf 文件，配置内容在上方自己看就行了，然后还是穿件数据目录和日志文件，更改属主属组，重载，启动和自启，查看 redis-sentimnel ，启动完 
          成后，开放端口和安全机制firewall-cmd --permanent --add-port=26379/tcp  firewall-cmd --reload setenforce 0,我上面有配置这一块的shell脚本直接用就完事了，
          记得每个slave节点都要用到，不然生效不了，最后的状态都为active就行，slave节点的哨兵部署完成，在slave节点上执行redis-cli -p 26379 SENTINEL masters 可以看到指           向的主节点，最后测试一遍在主节点上直接systemctl stop redis,在slave节点上 journalctl -u redis-sentinel -f 等待几秒，跳出日志，复制会话查看新的master节点              redis-cli -p 26379 SENTINEL replicas mymaster，然后查看最新的节点状态redis-cli -h 新主节点 -p 6379 -a 配置密码 INFO replication | grep -E 'role|connected_slaves|slave'，出现三个节点信息即为成功

    4（2）最后看我的配置文件内容和脚本即可




 

    



