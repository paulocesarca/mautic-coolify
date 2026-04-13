FROM php:8.2-fpm-alpine

RUN apk add --no-cache \
    nginx \
    curl \
    git \
    zip \
    unzip \
    mysql-client \
    supervisor \
    bash \
    nodejs \
    npm \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libldap \
    openldap-dev \
    icu-dev

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    mysqli \
    pdo \
    pdo_mysql \
    intl \
    zip \
    xml \
    mbstring \
    curl \
    ldap \
    opcache

RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "max_input_time = 300" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/custom.ini

WORKDIR /var/www

RUN git clone --depth 1 https://github.com/mautic/mautic.git /var/www/mautic
WORKDIR /var/www/mautic

RUN composer install --no-dev --prefer-dist --optimize-autoloader 2>&1 | head -100
RUN npm ci && npm run build

RUN mkdir -p var/cache var/logs var/sessions && \
    chmod -R 777 var/ && \
    chmod -R 777 app/cache

COPY local.php app/config/local.php
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80 9000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/api/v1/system/info || exit 1

CMD ["/start.sh"]
