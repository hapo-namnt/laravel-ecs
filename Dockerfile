FROM php:8.0.5-fpm-alpine

WORKDIR  /var/www

RUN apk update && apk add \
    build-base \
    freetype-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libzip-dev \
    zip \
    vim \
    unzip \
    git \
    jpegoptim optipng pngquant gifsicle \
    curl


RUN docker-php-ext-install pdo_mysql zip exif pcntl
RUN docker-php-ext-configure gd  --with-freetype=/usr/include/ --with-jpeg=/usr/include/
RUN docker-php-ext-install gd


RUN apk add autoconf && pecl install -o -f redis \
&& rm -rf /tmp/pear \
&& docker-php-ext-enable redis && apk del autoconf

COPY ./config/php/local.ini /usr/local/etc/php/conf.d/local.ini

RUN addgroup -g 1000 -S www && \
    adduser -u 1000 -S www -G www

ENV APP_HOME=/var/www/ \
    COMPOSER_CACHE_DIR=/dev/null \
    COMPOSER_VERSION=2.0.8

RUN php -r "readfile('http://getcomposer.org/installer');" | php -- \
    --install-dir=/usr/local/bin/ \
    --filename=composer \
    --version=${COMPOSER_VERSION}

COPY composer.json composer.lock ./

RUN composer install --no-autoloader --no-scripts --no-interaction

# Copy existing application directory contents
COPY . /var/www

RUN composer dump-autoload --optimize --no-interaction

# Copy existing application directory permissions
COPY --chown=www:www . /var/www

 RUN chown -R www:www /var/www/storage
 RUN chmod -R 755 /var/www/storage
 RUN chmod -R 755 storage bootstrap/cache
 RUN chmod -R 755 ./

# Change current user to www
USER www

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]


# COPY --chown=www:www-data . /var/www

# RUN chown -R www:www /var/www/storage
# RUN chmod -R 777 /var/www/storage

# USER www

# EXPOSE 9000
# CMD ["php-fpm"]
