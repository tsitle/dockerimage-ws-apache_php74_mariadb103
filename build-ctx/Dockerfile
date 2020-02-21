ARG CF_APACHE_BASE_IMGFULL

FROM ${CF_APACHE_BASE_IMGFULL}

ARG CF_APACHE_BASE_VER
ENV CF_APACHE_BASE_VER=${CF_APACHE_BASE_VER}

ENV DEBIAN_FRONTEND=noninteractive

ARG CF_PHP_FPM_VERSION="7.4"
ENV CF_PHP_FPM_VERSION=$CF_PHP_FPM_VERSION

ARG CF_MARIADB_VERSION

RUN \
	apt-get update \
	&& apt-get upgrade -y \
	&& apt-get dist-upgrade -y \
	# dotdeb sources
	&& echo "deb https://packages.sury.org/php/ ${CF_DEBIAN_RELEASE} main" >> /etc/apt/sources.list.d/php.list \
	# additional dotdeb source keys
	&& wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - \
	# update package lists
	&& apt-get update

RUN \
	# install packages
		apt-get update \
		&& apt-get install -y --no-install-recommends \
			# mariadb packages
				mariadb-client-${CF_MARIADB_VERSION} \
			# php packages
				php${CF_PHP_FPM_VERSION} \
				php${CF_PHP_FPM_VERSION}-fpm \
				php${CF_PHP_FPM_VERSION}-cli \
				php${CF_PHP_FPM_VERSION}-common \
				php${CF_PHP_FPM_VERSION}-opcache \
				php${CF_PHP_FPM_VERSION}-curl \
				php${CF_PHP_FPM_VERSION}-gd \
				php${CF_PHP_FPM_VERSION}-imap \
				php${CF_PHP_FPM_VERSION}-intl \
				php${CF_PHP_FPM_VERSION}-json \
				php${CF_PHP_FPM_VERSION}-mbstring \
				php${CF_PHP_FPM_VERSION}-mysql \
				php${CF_PHP_FPM_VERSION}-readline \
				php${CF_PHP_FPM_VERSION}-redis \
				php${CF_PHP_FPM_VERSION}-sqlite3 \
				php${CF_PHP_FPM_VERSION}-zip \
				php${CF_PHP_FPM_VERSION}-xml \
				php${CF_PHP_FPM_VERSION}-bcmath \
				#php${CF_PHP_FPM_VERSION}-mcrypt \
				php-pear \
				xml-core \
		|| exit 1; \
		if [ "$CF_CPUARCH_DEB_DIST" = "amd64" ]; then \
			apt-get install -y --no-install-recommends \
					php${CF_PHP_FPM_VERSION}-imagick \
					php${CF_PHP_FPM_VERSION}-xdebug \
			|| exit 1; \
		else \
			echo -n; \
		fi

#
RUN \
	apt-get --quiet --yes autoclean \
	&& apt-get --quiet --yes autoremove \
	&& apt-get --quiet --yes clean \
	&& rm -rf \
			/usr/share/man \
			/usr/share/doc \
			/usr/share/icons \
			/usr/share/poppler \
			/usr/share/mime \
			/var/lib/apt/lists*

#
ENV DEBIAN_FRONTEND=dialog

# install latest version of 'composer'
RUN \
	export EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"; \
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
	|| exit 1; \
	export ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"; \
	#
	if [ -z "$EXPECTED_SIGNATURE" ]; then \
		echo "EXPECTED_SIGNATURE empty !" >/dev/stderr; \
		exit 1; \
	fi; \
	if [ -z "$ACTUAL_SIGNATURE" ]; then \
		echo "ACTUAL_SIGNATURE empty !" >/dev/stderr; \
		exit 1; \
	fi; \
	if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then \
		echo 'ERROR: Invalid installer signature' >/dev/stderr; \
		exit 1; \
	fi; \
	#
	php composer-setup.php --quiet \
	&& rm composer-setup.php \
	&& chmod a+x composer.phar \
	&& mv composer.phar /usr/local/bin/composer \
	|| exit 1; \
	if [ ! -f /usr/share/doc/composer/copyright ]; then \
		mkdir -p /usr/share/doc/composer; \
		touch /usr/share/doc/composer/copyright; \
	fi

#
RUN \
	( a2dismod php${CF_PHP_FPM_VERSION} 2>/dev/null || echo -n "" ) \
	&& a2enconf php${CF_PHP_FPM_VERSION}-fpm \
	&& phpdismod xdebug

# copy config files
COPY files/php/ /etc/php/${CF_PHP_FPM_VERSION}/
COPY files/apache/* /etc/apache2/sites-available/

RUN \
	chmod 644 /etc/apache2/sites-available/* \
	&& chown root:root /etc/apache2/sites-available/* \
	|| exit 1; \
	test -d /root/apache-defaults || mkdir /root/apache-defaults; \
	cp /etc/apache2/sites-available/* /root/apache-defaults/

#
ENV TMP_WEBROOT_LAST_SITE=$CF_WEBROOT_SITE
ENV CF_WEBROOT_SITE=site-php

RUN \
	[ -n "${TMP_WEBROOT_LAST_SITE}" -a "${TMP_WEBROOT_LAST_SITE}" != "." -a "${TMP_WEBROOT_LAST_SITE}" != "./" ] \
	&& mv ${CF_WEBROOT}/${TMP_WEBROOT_LAST_SITE}/index.html ${CF_WEBROOT}/ \
	&& rmdir ${CF_WEBROOT}/${TMP_WEBROOT_LAST_SITE} \
	&& mkdir ${CF_WEBROOT}/${CF_WEBROOT_SITE} \
	&& chmod u=rwx,g=rwxs,o= ${CF_WEBROOT}/${CF_WEBROOT_SITE} \
	&& mv ${CF_WEBROOT}/index.html ${CF_WEBROOT}/${CF_WEBROOT_SITE}/

ENV TMP_WEBROOT_LAST_SITE=
