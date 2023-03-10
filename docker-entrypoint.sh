#! /bin/bash
set -eo pipefail
shopt -s nullglob
while ! nc -z $MYSQL_HOST 3306; do sleep 1; done

declare -g DATABASE_ALREADY_EXISTS

if mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST -e "use $MYSQL_DB"; then
    DATABASE_ALREADY_EXISTS="true"
    echo "Database $MYSQL_DB already exists.";
fi

sed -i "s/MYSQL_HOST/$MYSQL_HOST/" /etc/rd.conf
sed -i "s/RD_MYSQL_USER/$RD_MYSQL_USER/" /etc/rd.conf
sed -i "s/RD_MYSQL_PASS/$RD_MYSQL_PASS/" /etc/rd.conf
sed -i "s/MYSQL_DB/$MYSQL_DB/" /etc/rd.conf

#
# Create Rivendell Database
#
if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
    echo "CREATE DATABASE Rivendell;" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST
    echo "CREATE USER '$RD_MYSQL_USER'@'%' IDENTIFIED BY '$RD_MYSQL_PASS';" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST
    echo "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON $MYSQL_DB.* TO '$RD_MYSQL_USER'@'%';" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST
    echo "Creating $MYSQL_DB database"
    rddbmgr --create --generate-audio
    echo "UPDATE STATIONS set START_JACK='Y', JACK_COMMAND_LINE='/usr/bin/jackd --name default -d dummy -r 48000' WHERE NAME='rivendell';" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST $MYSQL_DB
fi

declare -g RD_USER_ALREADY_EXISTS
if id $RD_USER >> /dev/null; then
    RD_USER_ALREADY_EXISTS="true"
fi

#
# Create common directories
#
if [ -z "$RD_USER_ALREADY_EXISTS" ]; then

    adduser -c Rivendell\ Audio --groups audio,wheel $RD_USER && echo $RD_USER:$RD_USER_PASS | chpasswd

    mkdir -p /home/$RD_USER/rd_xfer
    chown $RD_USER:$RD_GROUP /home/$RD_USER/rd_xfer

    mkdir -p /home/$RD_USER/music_export
    chown $RD_USER:$RD_GROUP /home/$RD_USER/music_export

    mkdir -p /home/$RD_USER/music_import
    chown $RD_USER:$RD_GROUP /home/$RD_USER/music_import

    mkdir -p /home/$RD_USER/traffic_export
    chown $RD_USER:$RD_GROUP /home/$RD_USER/traffic_export

    mkdir -p /home/$RD_USER/traffic_import
    chown $RD_USER:$RD_GROUP /home/$RD_USER/traffic_import
fi

exec /usr/sbin/init

