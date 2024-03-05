FROM fifilyu/centos9:latest

ENV TZ Asia/Shanghai
ENV LANG en_US.UTF-8
ENV PATH="$PATH:/usr/local/python3/bin"

##############################################
# buildx有缓存，注意判断目录或文件是否已经存在
##############################################

# YUM源中的MySQL8在Docker中运行有权限问题，启动容器时必须添加 --cap-add=sys_nice 参数
RUN dnf install -y mysql-server

RUN dnf module -y enable nginx:$(dnf module list nginx | grep -E '^nginx\s+' | tail -n 1 | awk '{print $2}')
RUN dnf install -y nginx

RUN dnf module -y enable php:$(dnf module list php | grep -E '^php\s+' | tail -n 1 | awk '{print $2}')
RUN dnf install -y php-fpm php-cli php-bcmath php-gd php-mysqlnd php-pdo php-xml php-mbstring php-pecl-zip php-intl php-pecl-apcu

RUN dnf install -y php-pear php-devel
RUN pecl channel-update pecl.php.net

# EPEL源冲突，PECL方式安装模块
RUN dnf install -y ImageMagick-devel ImageMagick
RUN pecl install imagick

# EPEL源冲突，PECL方式安装模块
RUN dnf install -y libzstd-devel libzstd zstd redis lz4-devel lz4-libs
RUN pecl install --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="yes" enable-redis-zstd="yes" enable-redis-msgpack="no" enable-redis-lz4="yes" with-liblz4="yes"' redis

##############################################
# 设置PHP
##############################################
COPY file/etc/php.ini /etc/php.ini
COPY file/etc/php.d/50-imagick.ini /etc/php.d/50-imagick.ini
COPY file/etc/php.d/60-redis.ini /etc/php.d/60-redis.ini

# 验证pecl安装模块
RUN php -i | grep -E '^imagick module => enabled$'
RUN php -i | grep -E '^Redis Support => enabled$'

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

##############################################
# 设置Redis
##############################################
COPY file/etc/redis/redis.conf /etc/redis/redis.conf

RUN dnf clean all

COPY file/usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

WORKDIR /root

EXPOSE 22 8080
