# docker-lnmp

CentOS Stream 9 + Nginx + MySQL + PHP 的 Docker 镜像

## 一、构建镜像

```bash
git clone https://github.com/fifilyu/docker-lnmp.git
cd docker-lnmp
docker buildx build -t fifilyu/lnmp:latest .
```

## 二、开放端口

- sshd->22
- nginx->80

## 三、启动容器（数据分离）

### 3.1 预先准备开放权限的数据和日志目录

```bash
sudo mkdir -p /data/docker/volume/lnmp/var/log/{mysql,nginx,php-fpm} /data/docker/volume/lnmp/var/lib/mysql /data/docker/volume/lnmp/data/web /data/docker/volume/lnmp/var/lock/docker
sudo chmod -R 777 /data/docker/volume/lnmp/var/log/{mysql,nginx,php-fpm} /data/docker/volume/lnmp/var/lib/mysql /data/docker/volume/lnmp/var/lock/docker /data/docker/volume/lnmp/root/.mylogin.cnf
```

### 3.2 启动带目录映射的容器

```bash
docker run -d \
    --env LANG=en_US.UTF-8 \
    --env TZ=Asia/Shanghai \
    -e PUBLIC_STR="$(<~/.ssh/fifilyu@archlinux.pub)" \
    -p 5822:22 \
    -p 5880:80 \
    --cap-add=sys_nice \
    -v /data/docker/volume/lnmp/etc/php.ini:/etc/php.ini \
    -v /data/docker/volume/lnmp/etc/php-fpm.conf:/etc/php-fpm.conf \
    -v /data/docker/volume/lnmp/etc/php-fpm.d/www.conf:/etc/php-fpm.d/www.conf \
    -v /data/docker/volume/lnmp/etc/my.cnf.d/mysql-server.cnf:/etc/my.cnf.d/mysql-server.cnf \
    -v /data/docker/volume/lnmp/etc/nginx/nginx.conf:/etc/nginx/nginx.conf \
    -v /data/docker/volume/lnmp/etc/nginx/conf.d/www.conf:/etc/nginx/conf.d/www.conf \
    -v /data/docker/volume/lnmp/var/lib/mysql:/var/lib/mysql \
    -v /data/docker/volume/lnmp/data/web:/data/web \
    -v /data/docker/volume/lnmp/var/log/nginx:/var/log/nginx \
    -v /data/docker/volume/lnmp/var/log/mysql:/var/log/mysql \
    -v /data/docker/volume/lnmp/var/log/php-fpm:/var/log/php-fpm \
    -v /data/docker/volume/lnmp/var/lock/docker:/var/lock/docker \
    -v /data/docker/volume/lnmp/root/.mylogin.cnf:/root/.mylogin.cnf \
    -h lnmp \
    --name lnmp \
    fifilyu/lnmp:latest
```

- `--cap-add=sys_nice` 参数解决容器内运行 MySQL 的权限问题

### 3.3 重置目录权限

由 `docker-entrypoint.sh` 在容器启动时重置

_必须重启容器，否则容器无法读写映射目录_

```bash
docker restart lnmp
```

## 四、访问 lnmp

- 访问地址：http://localhost:5880
