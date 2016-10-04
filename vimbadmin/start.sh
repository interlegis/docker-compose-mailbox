#!/bin/bash

mysqlcheck() {
  # Wait for MySQL to be available...
  COUNTER=20
  until mysql -h mysql -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -e "show databases" 2>/dev/null; do
    echo "WARNING: MySQL still not up. Trying again..."
    sleep 10
    let COUNTER-=1
    if [ $COUNTER -lt 1 ]; then
      echo "ERROR: MySQL connection timed out. Aborting."
      exit 1
    fi
  done

  count=`mysql -h mysql -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -e "select count(*) from information_schema.tables where table_type='BASE TABLE' and table_schema='vimbadmin';" | tail -1`
  if [ "$count" == "0" ]; then
    echo "Database is empty. Creating database..."
    createdb
  fi
}

createdb() {
  if [ -z "$MAIL_MAX_QUOTA" ]; then
    MAIL_MAX_QUOTA=0
  else
    MAIL_MAX_QUOTA=$(( $MAIL_MAX_QUOTA * 1024 * 1024 ))
  fi
  if [ -z "$MAIL_MAX_MBOXES" ]; then
    MAIL_MAX_MBOXES=0;
  fi

  mysql -u root -p${MYSQL_ENV_MYSQL_ROOT_PASSWORD} -h mysql -e \
    "CREATE DATABASE vimbadmin;GRANT ALL ON vimbadmin.* TO vimbadmin IDENTIFIED BY '${MYSQL_ENV_MYSQL_ROOT_PASSWORD}';FLUSH PRIVILEGES;"
  sed -i -e "s %DB_PASSWORD% ${MYSQL_ENV_MYSQL_ROOT_PASSWORD} g" ${INSTALL_PATH}/application/configs/application.ini

  echo "Setting up DB and initial configuration..."

  HASH_PASS=`php -r "echo password_hash('$VIMBADMIN_SUPERUSER_PASSWORD', PASSWORD_DEFAULT);"`
  cd $INSTALL_PATH && ./bin/doctrine2-cli.php orm:schema-tool:create && \
  mysql -u vimbadmin -p${MYSQL_ENV_MYSQL_ROOT_PASSWORD} -h mysql vimbadmin -e \
    "INSERT INTO admin (username, password, super, active, created, modified) VALUES ('$VIMBADMIN_SUPERUSER', '$HASH_PASS', 1, 1, NOW(), NOW()); INSERT INTO domain (domain, max_quota, quota, max_mailboxes, transport, active, created, modified) VALUES ('$MAIL_DOMAIN', '$MAIL_MAX_QUOTA', '$MAIL_MAX_QUOTA', '$MAIL_MAX_MBOXES', 'virtual', 1, NOW(), NOW());" && \
  echo "Vimbadmin DB and Superuser setup completed successfully." 

  if [ -n "$VIMBADMIN_DOMAINADMIN_USER" ] && [ -n "$VIMBADMIN_DOMAINADMIN_PASSWORD" ]; then
     echo "Creating admin of the default mail domain..."
     HASH_ADMPASS=`php -r "echo password_hash('$VIMBADMIN_DOMAINADMIN_PASSWORD', PASSWORD_DEFAULT);"`
     mysql -u vimbadmin -p${MYSQL_ENV_MYSQL_ROOT_PASSWORD} -h mysql vimbadmin -e \
    "INSERT INTO admin (username, password, super, active, created, modified) VALUES ('$VIMBADMIN_DOMAINADMIN_USER', '$HASH_ADMPASS', 0, 1, NOW(), NOW()); INSERT INTO domain_admins (Admin_id, Domain_id) VALUES (2,1);" && \
     echo "Domain administrator for $MAIL_DOMAIN created successfully."
  fi
}


# SET PERMISSIONS
echo >&2 "Setting Permissions:"
path='/var/www/html'
htuser='www-data'

chown -R root:${htuser} ${path}/
chown -R ${htuser}:${htuser} ${path}/*

cp ${INSTALL_PATH}/public/.htaccess.dist ${INSTALL_PATH}/public/.htaccess

# CONF SETUP
sed -i "s/PRIMARY_HOSTNAME/${HOSTNAME}/g" /var/www/html/public/mail/config-v1.1.xml
sed -i "s/PRIMARY_HOSTNAME/${HOSTNAME}/g" /var/www/html/public/mail.mobileconfig.php
sed -i "s/UUID2/$(cat /proc/sys/kernel/random/uuid)/g"  /var/www/html/public/mail.mobileconfig.php
sed -i "s/UUID4/$(cat /proc/sys/kernel/random/uuid)/g" /var/www/html/public/mail.mobileconfig.php

sed -i -e "s %VIMBADMIN_REMEMBERME_SALT% ${VIMBADMIN_REMEMBERME_SALT} g" ${INSTALL_PATH}/application/configs/application.ini
sed -i -e "s %VIMBADMIN_PASSWORD_SALT% ${VIMBADMIN_PASSWORD_SALT} g" ${INSTALL_PATH}/application/configs/application.ini
sed -i -e "s/%VIMBADMIN_DOMAIN%/${VIMBADMIN_DOMAIN}/g" ${INSTALL_PATH}/application/configs/application.ini
sed -i -e "s/%VIMBADMIN_SUPERUSER%/${VIMBADMIN_SUPERUSER}/g" ${INSTALL_PATH}/application/configs/application.ini
sed -i -e "s/%VIMBADMIN_DOMAIN%/${VIMBADMIN_DOMAIN}/g" ${INSTALL_PATH}/application/configs/application.ini
sed -i -e "s/%MAIL_DOMAIN%/${MAIL_DOMAIN}/g" ${INSTALL_PATH}/application/configs/application.ini
sed -i -e "s/%MAIL_MX_DOMAIN%/${MAIL_MX_DOMAIN}/g" ${INSTALL_PATH}/application/configs/application.ini
sed -i -e "s/%MAIL_POSTMASTER%/${MAIL_POSTMASTER}/g" ${INSTALL_PATH}/application/configs/application.ini

# DB SETUP
mysqlcheck

# RUN IT
php-fpm
