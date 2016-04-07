#!/usr/bin/env bash
sed -i -e "s/%MAIL_MX_DOMAIN%/${MAIL_MX_DOMAIN}/g" /etc/dovecot/conf.d/15-lda.conf

if [ "${PLAINTEXT_AUTH}" = true ]; then
  sed -i -e "s/disable_plaintext_auth=yes/disable_plaintext_auth=no/g" /etc/dovecot/conf.d/10-ssl.conf
  sed -i -e "s/ssl = required//g" /etc/dovecot/conf.d/10-ssl.conf
fi
