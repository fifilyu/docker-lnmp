#!/bin/sh

/sbin/sshd

sleep 1

AUTH_LOCK_FILE=/var/log/docker_init_auth.lock

if [ ! -z "${PUBLIC_STR}" ]; then
    if [ -f ${AUTH_LOCK_FILE} ]; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") [信息] 跳过添加公钥"
    else
        echo "${PUBLIC_STR}" >>/root/.ssh/authorized_keys

        if [ $? -eq 0 ]; then
            echo "$(date "+%Y-%m-%d %H:%M:%S") [信息] 公钥添加成功"
            echo $(date "+%Y-%m-%d %H:%M:%S") >${AUTH_LOCK_FILE}
        else
            echo "$(date "+%Y-%m-%d %H:%M:%S") [错误] 公钥添加失败"
            exit 1
        fi
    fi
fi

PW=$(pwgen -1 20)
echo "$(date +"%Y-%m-%d %H:%M:%S") [信息] Root用户密码：${PW}"
echo "root:${PW}" | chpasswd

mkdir -p /data/web /var/log/{mysql,nginx,php-fpm}

# 使用容器内部的用户组重置目录权限：解决容器启动映射卷导致的宿主权限和容器权限不同步问题
chown -R apache:apache /data/web /var/log/php-fpm
chown -R mysql:mysql /var/log/mysql
chown -R nginx:nginx /var/log/nginx

# 为支持容器映射目录，只在启动时初始化数据目录
# --initialize-insecure 参数：root用户空密码
test -d /var/lib/mysql/mysql || /usr/libexec/mysqld --initialize-insecure=on --datadir=/var/lib/mysql --user=mysql

sleep 1

/usr/libexec/mysqld --basedir=/usr --user=mysql &

while true; do
    sleep 1
    mysql -e 'show databases;' 2>/dev/null

    if [ $? -eq 0 ]; then
        break
    fi
done

mkdir -p /var/lock/docker
LOCK_FILE=/var/lock/docker/mysql_init.lock

if [ -f ${LOCK_FILE} ]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") [信息] 跳过初始化MySQL密码"
else
    MYSQL_ROOT_PASSWORD=$(pwgen -1 20)
    echo "$(date "+%Y-%m-%d %H:%M:%S") [信息] MySQL新密码："${MYSQL_ROOT_PASSWORD}

    mysqladmin -uroot password ${MYSQL_ROOT_PASSWORD}

    if [ $? -eq 0 ]; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") [信息] MySQL密码修改成功"
    else
        echo "$(date "+%Y-%m-%d %H:%M:%S") [错误] MySQL密码修改失败"
        exit 1
    fi

    unbuffer expect -c "
    spawn mysql_config_editor set --skip-warn --login-path=client --host=localhost --user=root --password
    expect -nocase \"Enter password:\" {send \"${MYSQL_ROOT_PASSWORD}\n\"; interact}
    "

    mysql -e 'show databases;'

    if [ $? -eq 0 ]; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") [信息] MySQL无密码设置成功"
        echo $(date "+%Y-%m-%d %H:%M:%S") >${LOCK_FILE}
    else
        echo "$(date "+%Y-%m-%d %H:%M:%S") [错误] MySQL无密码设置失败"
        exit 1
    fi
fi

/usr/sbin/nginx

if [ $? -eq 0 ]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") [信息] Nginx启动成功"
else
    echo "$(date "+%Y-%m-%d %H:%M:%S") [错误] Nginx启动失败"
    exit 1
fi

mkdir -p /run/php-fpm
/usr/sbin/php-fpm -c /etc/php-fpm.conf

if [ $? -eq 0 ]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") [信息] php-fpm启动成功"
else
    echo "$(date "+%Y-%m-%d %H:%M:%S") [错误] php-fpm启动失败"
    exit 1
fi

sleep 2

# 目录降级读写权限，主要降级宿主映射卷
sudo chmod 755 /var/log/{mysql,nginx,php-fpm} /var/lock/docker

# 保持前台运行，不退出
while true; do
    sleep 3600
done
