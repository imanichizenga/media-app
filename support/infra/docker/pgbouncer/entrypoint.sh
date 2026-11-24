#!/bin/sh
# Transaction pooling on loopback; verified TLS to RDS. Config lives in /tmp: the root filesystem is read-only.
set -eu
umask 077
: "${DB_HOST:?}" "${DB_USER:?}" "${DB_NAME:?}" "${DB_PASSWORD:?}"
printf '"%s" "%s"\n' "$DB_USER" "$DB_PASSWORD" > /tmp/users.txt
cat > /tmp/pgbouncer.ini <<CONF
[databases]
$DB_NAME = host=$DB_HOST port=5432 dbname=$DB_NAME
[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432
auth_type = scram-sha-256
auth_file = /tmp/users.txt
pool_mode = transaction
max_client_conn = 400
default_pool_size = ${POOL_SIZE:-10}
reserve_pool_size = 5
server_tls_sslmode = ${SERVER_TLS:-verify-full}
server_tls_ca_file = /etc/ssl/rds.pem
ignore_startup_parameters = extra_float_digits
unix_socket_dir =
log_connections = 0
log_disconnections = 0
CONF
unset DB_PASSWORD
exec pgbouncer /tmp/pgbouncer.ini
