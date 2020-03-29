# Apache2 + PHP 7.4 + MariaDB 10.3 Client Docker Image for AARCH64, ARMv7l, X86 and X64

For hosting PHP powered websites.

## Inheritance and added packages
- Docker Image **tsle/ws-apache-base** (see [https://github.com/tsitle/dockerimage-ws-apache\_base](https://github.com/tsitle/dockerimage-ws-apache_base))
	- PHP 7.4 (CLI + FPM)
	- PHP packages (see below)
	- MariaDB Client 10.3 (^= MySQL 5.7/8.0)
	- php-pear
	- xml-core

## PHP Packages included
- bcmath
- cli
- common
- curl
- fpm
- gd
- imagick (only on X64)
- imap
- json
- mbstring
- mcrypt
- mysql
- opcache
- readline
- redis
- sqlite3
- xdebug (only on X64)
- xml
- zip

## Webserver TCP Port
The webserver is listening only on TCP port 80 by default.

## Docker Container usage
See the related GitHub repository [https://github.com/tsitle/dockercontainer-ws-apache\_php74\_mariadb103](https://github.com/tsitle/dockercontainer-ws-apache_php74_mariadb103)

## Docker Container configuration
From **tsle/ws-apache-base**:

- CF\_PROJ\_PRIMARY\_FQDN [string]: FQDN for website (e.g. "mywebsite.localhost") (default: empty)
- CF\_SET\_OWNER\_AND\_PERMS\_WEBROOT [bool]: Recursively chown and chmod CF\_WEBROOT? (default: false)
- CF\_WWWDATA\_USER\_ID [int]: User-ID for www-data (default: 33)
- CF\_WWWDATA\_GROUP\_ID [int]: Group-ID for www-data (default: 33)
- CF\_ENABLE\_CRON [bool]: Enable cron service? (default: false)
- CF\_LANG [string]: Language to use (en\_EN.UTF-8 or de\_DE.UTF-8) (default: empty)
- CF\_TIMEZONE [string]: Timezone (e.g. 'Europe/Berlin') (default: empty)
- CF\_ENABLE\_HTTP [bool]: Enable HTTP for Apache? (default: true)
- CF\_CREATE\_DEFAULT\_HTTP\_SITE [bool]: Create default HTTP Virtual Host for Apache? (default: true)
- CF\_ENABLE\_HTTPS [bool]: Enable HTTPS/SSL for Apache? (default: false)
- CF\_CREATE\_DEFAULT\_HTTPS\_SITE [bool]: Create default HTTPS/SSL Virtual Host for Apache? (default: true)
- CF\_SSLCERT\_GROUP\_ID [int]: Group-ID for ssl-cert (default: 102)
- CF\_DEBUG\_SSLGEN\_SCRIPT [bool]: Enable debug out for sslgen.sh?
- CF\_CSR\_SUBJECT\_COUNTRY [string]: For auto-generated SSL Certificates (default: DE)
- CF\_CSR\_SUBJECT\_STATE [string]: For auto-generated SSL Certificates (default: SAX)
- CF\_CSR\_SUBJECT\_LOCATION [string]: For auto-generated SSL Certificates (default: LE)
- CF\_CSR\_SUBJECT\_ORGANIZ [string]: For auto-generated SSL Certificates (default: The IT Company)
- CF\_CSR\_SUBJECT\_ORGUNIT [string]: For auto-generated SSL Certificates (default: IT)

From this image:

- CF\_WWWFPM\_USER\_ID [int]: User-ID for wwwphpfpm (default: 1000)
- CF\_WWWFPM\_GROUP\_ID [int]: Group-ID for wwwphpfpm (default: 1000)
- CF\_PHPFPM\_RUN\_AS\_WWWDATA [bool]: Run PHP-FPM process as user/group www-data ? (default: false)
- CF\_PHPFPM\_ENABLE\_OPEN\_BASEDIR [bool]: (default: false)
- CF\_PHPFPM\_UPLOAD\_TMP\_DIR [string]: (default: "/var/www/upload\_tmp\_dir")
- CF\_PHPFPM\_PM\_MAX\_CHILDREN [int]: (default: 5)
- CF\_PHPFPM\_PM\_START\_SERVERS [int]: (default: 2)
- CF\_PHPFPM\_PM\_MIN\_SPARE\_SERVERS [int]: (default: 1)
- CF\_PHPFPM\_PM\_MAX\_SPARE\_SERVERS [int]: (default: 3)
- CF\_PHPFPM\_UPLOAD\_MAX\_FILESIZE [sizestring]: (default: "100M")
- CF\_PHPFPM\_POST\_MAX\_SIZE [sizestring]: (default: "100M")
- CF\_PHPFPM\_MEMORY\_LIMIT [sizestring]: (default: "512M")
- CF\_PHPFPM\_MAX\_EXECUTION\_TIME [int]: (default: 600)
- CF\_PHPFPM\_MAX\_INPUT\_TIME [int]: (default: 600)
- CF\_PHPFPM\_HTML\_ERRORS [bool]: (default: false)

Only on X64:

- CF\_ENABLE\_XDEBUG [bool]: Enable XDebug PHP module? (default: false)
- CF\_XDEBUG\_REMOTE\_HOST [string]: Remote Host for XDebug (default 'dockerhost')

## Using cron
You'll need to create the crontab file `./mpcron/wwwphpfpm` and then add some task to the file:

```
# the following command will be executed as 'wwwphpfpm'
* *    *   *   *     cd /var/www/html/; tar cf backup.tar site-html/> /dev/null 2>&1
```

Instead of the username `wwwphpfpm` you could also use `root`.

Now you could enable cron in your docker-compose.yaml file like this:

```
version: '3.5'
services:
  apache:
    image: "ws-apache-php74-mariadb103-<ARCH>:<VERSION>"
    ports:
      - "80:80"
    volumes:
      - "$PWD/mpweb:/var/www/html"
      - "$PWD/mpcron/wwwphpfpm:/var/spool/cron/crontabs/wwwphpfpm"
    environment:
      - CF_PROJ_PRIMARY_FQDN=example-host.localhost
      - CF_WWWFPM_USER_ID=<YOUR_UID>
      - CF_WWWFPM_GROUP_ID=<YOUR_GID>
      - CF_SET_OWNER_AND_PERMS_WEBROOT=false
      - CF_ENABLE_CRON=true
      - CF_LANG=de_DE.UTF-8
      - CF_TIMEZONE=Europe/Berlin
    restart: unless-stopped
    stdin_open: false
    tty: false
```

## Enabling the PHP Module XDebug (only on X64)
The PHP Module 'xdebug' is disabled by default.  
To enable it you'll need to follow these steps from within a Bash shell:  
(replace "DOCKERCONTAINER" with your Docker Container's name)

1. Start the Docker Container
2. If your debugger (e.g. IntelliJ) is running on a different machine then
	you'll need to replace the default hostname "host" with your machine's hostname.  
	Edit XDebug configuration:  
	```
	$ docker exec -it DOCKERCONTAINER nano /etc/php/7.4/mods-available/xdebug.ini
	```  

	```
	xdebug.remote_host="host"
	```  
	When done editing hit CTRL-X, then "J" and hit ENTER
3. Now enable the PHP Module:  
	```  
	$ docker exec -it DOCKERCONTAINER phpenmod xdebug
	```  
	```  
	$ docker exec -it DOCKERCONTAINER service php7.4-fpm restart
	```

## Disabling the PHP Module XDebug (only on X64)
```  
$ docker exec -it DOCKERCONTAINER phpdismod xdebug
```  
```  
$ docker exec -it DOCKERCONTAINER service php7.4-fpm restart
```
