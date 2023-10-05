FROM ubuntu:22.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
	curl \
	software-properties-common \
	sudo

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
	nginx-extras

# Install PHP 8.2 and some extensions
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
RUN apt search php8.2-dom
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
	php8.2-cli \
	php8.2-curl \
	php8.2-fpm \
	php8.2-gd \
	php8.2-mbstring \
	php8.2-mysql \
	php8.2-xdebug \
	php8.2-xml \
	php8.2-zip \
	composer

	# php8.2-dom
	# php8.2-dev \

# Copy nginx default site configuration
ADD default /etc/nginx/sites-available/default

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

# PHP-FPM: log errors to stderr
RUN sed -i 's/error_log = \/var\/log\/php8.2-fpm.log/error_log = \/proc\/self\/fd\/2/' /etc/php/8.2/fpm/php-fpm.conf
# PHP-FPM: log workers errors
RUN sed -i 's/;catch_workers_output = yes/catch_workers_output = yes/' /etc/php/8.2/fpm/pool.d/www.conf
RUN sed -i 's/;decorate_workers_output = no/decorate_workers_output = no/' /etc/php/8.2/fpm/pool.d/www.conf
# PHP-FPM: log access to stdout
RUN sed -i 's/;access.log = log\/$pool.access.log/access.log = \/proc\/self\/fd\/1/' /etc/php/8.2/fpm/pool.d/www.conf

RUN mkdir /run/php/

RUN echo "<?php phpinfo(); ?>" > /var/www/index.php

RUN usermod -u 1000 www-data

VOLUME ["/var/www"]

EXPOSE 80

CMD service nginx start && php-fpm8.2 -F
