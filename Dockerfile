FROM fifilyu/centos9:latest

ENV TZ Asia/Shanghai
ENV LANG en_US.UTF-8
ENV PATH="$PATH:/usr/local/python3/bin"

##############################################
# buildx有缓存，注意判断目录或文件是否已经存在
##############################################

# YUM源中的MySQL8在Docker中运行有权限问题，启动容器时必须添加 --cap-add=sys_nice 参数
RUN dnf install -y mysql-server nginx php-fpm php-cli php-bcmath php-gd php-mysqlnd php-pdo php-xml php-tidy

##############################################
# 设置PHP
##############################################
COPY file/etc/php.ini /etc/php.ini
COPY file/etc/php-fpm.conf /etc/php-fpm.conf
COPY file/etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf

##############################################
# 设置MySQL
##############################################
COPY file/etc/my.cnf.d/mysql-server.cnf /etc/my.cnf.d/mysql-server.cnf

##############################################
# 设置Nginx
##############################################
COPY file/etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY file/etc/nginx/conf.d/www.conf /etc/nginx/conf.d/www.conf
COPY file/data/web/index.php /data/web/index.php

RUN dnf clean all

COPY file/usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

WORKDIR /root

EXPOSE 22 8080
