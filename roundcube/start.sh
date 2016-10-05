#!/bin/bash

# CONF SETUP
if [ -z "$PASSDB_PASSWORD" ]; then
  PASSDB_PASSWORD=${MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi

sed -i -e "s/%ROUNDCUBE_DOMAIN%/${ROUNDCUBE_DOMAIN}/g" /etc/nginx/conf.d/roundcube.conf
sed -i -e "s#%RANDOM_DES_KEY%#`openssl rand -base64 16`#g" ${INSTALL_PATH}/config/config.inc.php
sed -i -e "s/%DB_PASSWORD%/${MYSQL_ENV_MYSQL_ROOT_PASSWORD}/g" ${INSTALL_PATH}/config/config.inc.php
sed -i -e "s/%MAIL_DOMAIN%/${MAIL_DOMAIN}/g" ${INSTALL_PATH}/config/config.inc.php
sed -i -e "s/%PASSDB_USER%/${PASSDB_USER}/g" ${INSTALL_PATH}/plugins/password/config.inc.php
sed -i -e "s/%PASSDB_PASSWORD%/${PASSDB_PASSWORD}/g" ${INSTALL_PATH}/plugins/password/config.inc.php
sed -i -e "s/%PASSDB_HOST%/${PASSDB_HOST}/g" ${INSTALL_PATH}/plugins/password/config.inc.php
sed -i -e "s/%PASSDB_NAME%/${PASSDB_NAME}/g" ${INSTALL_PATH}/plugins/password/config.inc.php

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

  count=`mysql -h mysql -u root -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -e "select count(*) from information_schema.tables where table_type='BASE TABLE' and table_schema='roundcube';" | tail -1`
  if [ "$count" == "0" ]; then
    echo "Database is empty. Creating database..."
    createdb
  fi
}

createdb() {
  mysql -u root -p${MYSQL_ENV_MYSQL_ROOT_PASSWORD} -h mysql -e \
    "CREATE DATABASE roundcube;GRANT ALL ON roundcube.* TO roundcube IDENTIFIED BY '${MYSQL_ENV_MYSQL_ROOT_PASSWORD}';FLUSH PRIVILEGES;" && \
  mysql -u roundcube -p${MYSQL_ENV_MYSQL_ROOT_PASSWORD} -h mysql roundcube < ${INSTALL_PATH}/SQL/mysql.initial.sql &> /dev/null && \
  echo "Roundcube setup completed successfully"
}

mysqlcheck

# RUN IT
php-fpm

