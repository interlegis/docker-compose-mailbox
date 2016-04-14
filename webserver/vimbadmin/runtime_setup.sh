#!/bin/bash

# CONF SETUP
sed -i -e "s/%VIMBADMIN_DOMAIN%/${VIMBADMIN_DOMAIN}/g" /etc/nginx/sites-enabled/vimbadmin
sed -i -e "s %VIMBADMIN_REMEMBERME_SALT% ${VIMBADMIN_REMEMBERME_SALT} g" ${vimbadmin_install_path}/application/configs/application.ini
sed -i -e "s %VIMBADMIN_PASSWORD_SALT% ${VIMBADMIN_PASSWORD_SALT} g" ${vimbadmin_install_path}/application/configs/application.ini
sed -i -e "s/%VIMBADMIN_DOMAIN%/${VIMBADMIN_DOMAIN}/g" ${vimbadmin_install_path}/application/configs/application.ini
sed -i -e "s/%VIMBADMIN_SUPERUSER%/${VIMBADMIN_SUPERUSER}/g" ${vimbadmin_install_path}/application/configs/application.ini
sed -i -e "s/%VIMBADMIN_DOMAIN%/${VIMBADMIN_DOMAIN}/g" ${vimbadmin_install_path}/application/configs/application.ini
sed -i -e "s/%MAIL_DOMAIN%/${MAIL_DOMAIN}/g" ${vimbadmin_install_path}/application/configs/application.ini
sed -i -e "s/%MAIL_MX_DOMAIN%/${MAIL_MX_DOMAIN}/g" ${vimbadmin_install_path}/application/configs/application.ini
sed -i -e "s/%MAIL_POSTMASTER%/${MAIL_POSTMASTER}/g" ${vimbadmin_install_path}/application/configs/application.ini

# DB SETUP
MAX_TIMEOUTS=0

while [ $MAX_TIMEOUTS -lt 30 ]; do
  mysql -u root -ppassword -h mysql -e "" &> /dev/null
  if [ $? -eq 0 ]; then
    break
  else
    sleep 1
  fi
  let MAX_TIMEOUTS=MAX_TIMEOUTS+1
  if [ $MAX_TIMEOUTS -gt 29 ]; then
    echo "ERROR: Could never connect to database $MAX_TIMEOUTS"
  fi
done
mysql -u root -ppassword -h mysql vimbadmin -e "" &> /dev/null

if [ $? -eq 0 ]; then
  echo "Using existing DB"
else
  if [ -z "$MAIL_MAX_QUOTA" ]; then
    MAIL_MAX_QUOTA=0
  else
    MAIL_MAX_QUOTA=$(( $MAIL_MAX_QUOTA * 1024 * 1024 ))
  fi
  if [ -z "$MAIL_MAX_MBOXES" ]; then
    MAIL_MAX_MBOXES=0;
  fi

  echo "Setting up DB and initial configuration..."

  mysql -u root -ppassword -h mysql < /tmp/vimbadmin/db_setup.sql &> /dev/null && \
  HASH_PASS=`php -r "echo password_hash('$VIMBADMIN_SUPERUSER_PASSWORD', PASSWORD_DEFAULT);"`
  cd $vimbadmin_install_path && ./bin/doctrine2-cli.php orm:schema-tool:create && \
  mysql -u vimbadmin -ppassword -h mysql vimbadmin -e \
    "INSERT INTO admin (username, password, super, active, created, modified) VALUES ('$VIMBADMIN_SUPERUSER', '$HASH_PASS', 1, 1, NOW(), NOW()); INSERT INTO domain (domain, max_quota, quota, max_mailboxes, transport, active, created, modified) VALUES ('$MAIL_DOMAIN', '$MAIL_MAX_QUOTA', '$MAIL_MAX_QUOTA', '$MAIL_MAX_MBOXES', 'virtual', 1, NOW(), NOW());" && \
  echo "Vimbadmin DB and Superuser setup completed successfully." 

  if [ -n "$VIMBADMIN_DOMAINADMIN_USER" ] && [ -n "$VIMBADMIN_DOMAINADMIN_PASSWORD" ]; then
     echo "Creating admin of the default mail domain..."
     HASH_ADMPASS=`php -r "echo password_hash('$VIMBADMIN_DOMAINADMIN_PASSWORD', PASSWORD_DEFAULT);"`
     mysql -u vimbadmin -ppassword -h mysql vimbadmin -e \
    "INSERT INTO admin (username, password, super, active, created, modified) VALUES ('$VIMBADMIN_DOMAINADMIN_USER', '$HASH_ADMPASS', 0, 1, NOW(), NOW()); INSERT INTO domain_admins (Admin_id, Domain_id) VALUES (2,1);" && \
     echo "Domain administrator for $MAIL_DOMAIN created successfully."
  fi
fi

