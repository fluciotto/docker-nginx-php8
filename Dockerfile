FROM ubuntu:24.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
	curl \
	software-properties-common \
	sudo

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
	nginx-extras

# Install PHP 8.5 and some extensions
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
	php8.5-cli \
	php8.5-curl \
	php8.5-fpm \
	php8.5-gd \
	php8.5-mbstring \
	php8.5-mysql \
	php8.5-xdebug \
	php8.5-xml \
	php8.5-zip \
	composer

	# php8.5-dom
	# php8.5-dev \

# Copy nginx default site configuration
ADD default /etc/nginx/sites-available/default

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

# PHP-FPM: log errors to stderr
RUN sed -i 's/error_log = \/var\/log\/php8.5-fpm.log/error_log = \/proc\/self\/fd\/2/' /etc/php/8.5/fpm/php-fpm.conf
# PHP-FPM: log workers errors
RUN sed -i 's/;catch_workers_output = yes/catch_workers_output = yes/' /etc/php/8.5/fpm/pool.d/www.conf
RUN sed -i 's/;decorate_workers_output = no/decorate_workers_output = no/' /etc/php/8.5/fpm/pool.d/www.conf
# PHP-FPM: log access to stdout
RUN sed -i 's/;access.log = log\/$pool.access.log/access.log = \/proc\/self\/fd\/1/' /etc/php/8.5/fpm/pool.d/www.conf

RUN echo "<?php phpinfo(); ?>" > /var/www/index.php

# RUN usermod -u 1000 www-data

VOLUME ["/var/www"]

EXPOSE 80

CMD service nginx start && php-fpm8.5 -F
