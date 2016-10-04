<?php

$config['password_confirm_current'] = true;
$config['password_db_dsn'] = 'mysql://%PASSDB_USER%:%PASSDB_PASSWORD%@%PASSDB_HOST%/%PASSDB_NAME%';
$config['password_crypt_hash'] = 'sha256';
$config['password_query'] = 'UPDATE mailbox SET password=%c WHERE username=%u';
