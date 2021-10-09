ARG TAG=7.4-fpm

# FROM php:7.4-fpm-alpine # alpine does not work with pecl extensions for the lack of glibc
FROM php:${TAG}

LABEL maintainer "Tunghsiao Liu <t@sparanoid.com>"

WORKDIR /app

# Use the default configuration
# $PHP_INI_DIR default to /usr/local/etc/php/
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN apt-get update \
    && apt-get install -y libpq-dev libzip-dev libpng-dev libicu-dev libmagickwand-dev \
    && docker-php-ext-install -j$(nproc) bcmath mysqli pdo_mysql pgsql pdo_pgsql exif zip gd intl opcache \
    # PECL extensions should be installed in series to fail properly if something went wrong.
    # Otherwise errors are just skipped by PECL.
    && pecl install apcu \
    && pecl install igbinary \
    && pecl install imagick \
    && pecl install msgpack \
    && pecl install redis \
    && docker-php-ext-enable apcu igbinary imagick msgpack redis \
    && rm -rf /var/lib/apt/lists/*

# Setup php.ini
RUN sed -i -r "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" "$PHP_INI_DIR/php.ini" \
    && sed -i -r "s/expose_php = On/expose_php = Off/g" "$PHP_INI_DIR/php.ini" \
    && sed -i -r "s/post_max_size = 8M/post_max_size = 16M/g" "$PHP_INI_DIR/php.ini" \
    && sed -i -r "s/upload_max_filesize = 2M/upload_max_filesize = 16M/g" "$PHP_INI_DIR/php.ini" \
    && sed -i -r "s/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 86401/g" "$PHP_INI_DIR/php.ini" \
    && sed -i -r "s/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 86401/g" "$PHP_INI_DIR/php.ini" \
    && sed -i -r "s/max_execution_time = 30/max_execution_time = 180/g" "$PHP_INI_DIR/php.ini"

# Setup OPcache
RUN echo "opcache.enable = 1" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.enable_cli = 1" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.memory_consumption = 512" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.interned_strings_buffer = 8" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.max_accelerated_files = 50000" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.revalidate_freq = 5" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.save_comments = 0" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.enable_file_override = 1" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.huge_code_pages = 0" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.fast_shutdown = 1" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini"

# Setup FPM global config
# Insert before [www] directive
RUN sed -i '0,/^\[www\].*/s/^\[www\].*/emergency_restart_threshold = 10\n&/' "/usr/local/etc/php-fpm.d/docker.conf" \
    && sed -i '0,/^\[www\].*/s/^\[www\].*/emergency_restart_interval = 1m\n&/' "/usr/local/etc/php-fpm.d/docker.conf" \
    && sed -i '0,/^\[www\].*/s/^\[www\].*/process_control_timeout = 5\n&/' "/usr/local/etc/php-fpm.d/docker.conf"

# Setup FPM `www` (default) pool
RUN sed -i -r "s/pm.max_children = 5/pm.max_children = 640/g" "/usr/local/etc/php-fpm.d/www.conf" \
    && sed -i -r "s/pm.start_servers = 2/pm.start_servers = 18/g" "/usr/local/etc/php-fpm.d/www.conf" \
    && sed -i -r "s/pm.min_spare_servers = 1/pm.min_spare_servers = 12/g" "/usr/local/etc/php-fpm.d/www.conf" \
    && sed -i -r "s/pm.max_spare_servers = 3/pm.max_spare_servers = 24/g" "/usr/local/etc/php-fpm.d/www.conf" \
    && sed -i -r "s/;pm.process_idle_timeout = 10s/pm.process_idle_timeout = 10s/g" "/usr/local/etc/php-fpm.d/www.conf" \
    && sed -i -r "s/;pm.max_requests = 500/pm.max_requests = 500/g" "/usr/local/etc/php-fpm.d/www.conf" \
    && sed -i -r "s/max_execution_time = 30/max_execution_time = 180/g" "/usr/local/etc/php-fpm.d/www.conf"

# Setup Redis
RUN echo "php_value[session.save_handler] = redis" >> "/usr/local/etc/php-fpm.d/www.conf" \
    && echo "php_value[session.save_path] = tcp://redis:6379" >> "/usr/local/etc/php-fpm.d/www.conf"
