# Docker PHP-FPM

Homemade PHP-FPM Docker image with additional extensions based on [official PHP images](https://hub.docker.com/_/php).

This image is mainly used for development environments but the default configurations are production-ready to handle small to medium-sized PHP sites.

- [Docker Hub](https://hub.docker.com/r/sparanoid/php-fpm)
- [ghcr.io](https://github.com/users/sparanoid/packages/container/package/php-fpm)

## Available Tags

- 8.1 (default), 8, 7.4
- local, dockerhub, \<branch\>, edge, sha-\<hash\>, latest (default to `8.1`)

## Built-in Extensions

This image is bundled with additional extensions that should work with most modern PHP applications. Tested with WordPress, MediaWiki and Flarum.

- apcu
- bcmath
- exif
- gd (with freetype, jpeg, and webp)
- igbinary
- imagick
- intl
- msgpack
- opcache
- pdo_mysql
- pdo_pgsql
- redis
- zip

You can view full built-in extensions:

```bash
docker run --rm -it --name tmp-php-fpm sparanoid/php-fpm:latest php -m
```

## Key Files and Directories

- `/app` - Default PHP working directory (`WORKDIR`)
- `/usr/local/etc/php-fpm.conf` - Global FPM settings
- `/usr/local/etc/php/conf.d/` - Custom PHP configurations
- `/usr/local/etc/php-fpm.d/` - PHP-FPM configurations
  - `/usr/local/etc/php-fpm.d/www.conf` - Default `www` pool settings

You can eject and inspect these configs by using the following commands:

```bash
docker run --name tmp-php -d sparanoid/php-fpm:latest
docker cp tmp-php:/usr/local/etc/ $(pwd)/ejected-php-fpm
docker rm -f tmp-php
```

## Extra Packages

- ImageMagick
- zip
- unzip

## Examples

Using this image with ejected WordPress, Nginx, MariaDB, Redis and Adminer.

Edit `docker-compose.yml`:

```yaml
version: '3'

services:
  nginx:
    image: nginx:alpine
    restart: always
    ports:
      - 80:80
      # Enable 443 on production
      # - 443:443
    depends_on:
      - php
    volumes:
      - ./data/nginx:/app
      - ./config/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf:ro

  php:
    image: sparanoid/php-fpm:8-latest
    restart: always
    depends_on:
      - redis
      - mariadb
    volumes:
      - ./data/nginx:/app

  mariadb:
    image: mariadb
    restart: always
    volumes:
      - wordpress-db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-password}
      - MYSQL_DATABASE=wordpress

  redis:
    image: redis
    restart: always

  adminer:
    image: adminer
    restart: always
    ports:
      - 127.0.0.1:8080:8080
    depends_on:
      - php

volumes:
  wordpress-db:
```

Edit `./config/nginx/conf.d/default.conf`:

```nginx
  server {
    listen                  80;
    index                   index.html index.htm index.php;

    root                    /app;

    location / {
      try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
      try_files               $uri =404;
      fastcgi_pass            php:9000;
      include                 fastcgi_params;
      fastcgi_index           index.php;
      fastcgi_param           SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
  }
```

In order to make [Redis Object Cache](https://wordpress.org/plugins/redis-cache/) plugin work with Redis container. Add the following line in `./data/nginx/wp-config.php`:

```php
define( 'WP_REDIS_HOST', 'redis' );
```
