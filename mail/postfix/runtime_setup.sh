#!/usr/bin/env bash
sed -i -e "s/%MAIL_DOMAIN%/${MAIL_DOMAIN}/g" /etc/postfix/main.cf
sed -i -e "s/%MAIL_MX_DOMAIN%/${MAIL_MX_DOMAIN}/g" /etc/postfix/main.cf

# configure password
sed -i -e "s/%DB_PASSWORD%/${MYSQL_ENV_MYSQL_ROOT_PASSWORD}/g" /etc/postfix/mysql/virtual_alias_maps.cf
sed -i -e "s/%DB_PASSWORD%/${MYSQL_ENV_MYSQL_ROOT_PASSWORD}/g" /etc/postfix/mysql/virtual_mailbox_maps.cf
sed -i -e "s/%DB_PASSWORD%/${MYSQL_ENV_MYSQL_ROOT_PASSWORD}/g" /etc/postfix/mysql/virtual_domains_maps.cf
sed -i -e "s/%DB_PASSWORD%/${MYSQL_ENV_MYSQL_ROOT_PASSWORD}/g" /etc/postfix/mysql/virtual_transport_maps.cf

# Make mail log to syslog
sed -i -e "s#/var/log/mail.log#/var/log/syslog#g" /etc/syslog-ng/syslog-ng.conf

# Copy hosts file to chroot jail so that postfix can resolve opendkim
cp /etc/hosts /var/spool/postfix/etc/hosts
cp /etc/services /var/spool/postfix/etc/services
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf
