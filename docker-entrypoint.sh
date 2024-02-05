#!/bin/sh
set -eo pipefail
shopt -s nullglob

# Wait for database to come online.
while ! nc -z $MYSQL_HOSTNAME 3306; do sleep 1; done

source /run/secrets/start_config
/usr/local/bin/installer_install_rivendell.sh --$MODE

exec /usr/sbin/init

