From composer:1.9 as vendor
COPY database/ database/
COPY composer.json composer.json
COPY composer.lock composer.lock
RUN composer install --no-scripts --ansi --no-interaction

FROM node:12.12 as frontend
RUN mkdir -p /app/public
COPY package.json webpack.mix.js /app/
COPY resources/ /app/resources/
WORKDIR /app
RUN npm install && npm run production

FROM php:7.3.10-apache-stretch
RUN docker-php-ext-install pdo_mysql

ARG uid
RUN useradd -o -u ${uid} -g www-data -m -s /bin/bash www
COPY --chown=www-data:www-data . /var/www/html
COPY --chown=www-data:www-data --from=vendor /app/vendor /var/www/html/vendor/
COPY --chown=www-data:www-data --from=frontend /app/public/js /var/www/html/public/js/
COPY --chown=www-data:www-data --from=frontend /app/public/css /var/www/html/public/css/
COPY --chown=www-data:www-data --from=frontend /app/mix-manifest.json /var/www/html/mix-manifest.json/

RUN chown -R www-data:www-data /var/www/html/storage

#ENV APACHE_DOCUMENT_ROOT /var/www/html/public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN sed -s -i -e "s/80/8000/" /etc/apache2/ports.conf /etc/apache2/sites-available/*.conf

RUN a2enmod rewrite

# run the container as www user
USER www



