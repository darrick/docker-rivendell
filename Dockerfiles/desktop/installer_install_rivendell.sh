#!/bin/sh

# installer_install_rivendell.sh
#
# Install Rivendell 4.x on an RHEL 8 system
#

#
# Site Defines
#
USER_NAME="rd"

# USAGE: AddDbUser <dbname> <hostname> <username> <password>
function AddDbUser {
    echo "CREATE USER IF NOT EXISTS '${3}'@'${2}' IDENTIFIED BY '${4}';" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOSTNAME
    echo "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON ${1}.* TO '${3}'@'${2}';" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOSTNAME
    echo "FLUSH PRIVILEGES;" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOSTNAME
}

function GenerateDefaultRivendellConfiguration {
    mkdir -p /etc/rivendell.d
    cat /usr/share/rhel-rivendell-installer/rd.conf-sample | sed s/%MYSQL_HOSTNAME%/$MYSQL_HOSTNAME/g | sed s/%MYSQL_LOGINNAME%/$MYSQL_LOGINNAME/g | sed s/%MYSQL_PASSWORD%/$MYSQL_PASSWORD/g | sed s^%NFS_MOUNT_SOURCE%^$NFS_MOUNT_SOURCE^g | sed s/%NFS_MOUNT_TYPE%/$NFS_MOUNT_TYPE/g > /etc/rivendell.d/rd-default.conf
    ln -s -f /etc/rivendell.d/rd-default.conf /etc/rd.conf
}

GenerateDefaultRivendellConfiguration

if ! id $USER_NAME >> /dev/null; then
    adduser -c Rivendell\ Audio --groups audio,wheel $USER_NAME && echo $USER_NAME:$USER_PASSWORD | chpasswd
fi

if test $MODE = "server" ; then

    #
    # Create Empty Database
    #
    echo "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOSTNAME
    AddDbUser $MYSQL_DATABASE "%" $MYSQL_LOGINNAME $MYSQL_PASSWORD

    #
    # Create Rivendell Database
    #
    rddbmgr --create --generate-audio

    #
    # Create common directories
    #
    mkdir -p /home/$USER_NAME/rd_xfer
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/rd_xfer

    mkdir -p /home/$USER_NAME/music_export
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/music_export

    mkdir -p /home/$USER_NAME/music_import
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/music_import

    mkdir -p /home/$USER_NAME/traffic_export
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/traffic_export

    mkdir -p /home/$USER_NAME/traffic_import
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/traffic_import
fi

if test $MODE = "client" ; then

    AddDbUser $MYSQL_DATABASE "%" $MYSQL_LOGINNAME $MYSQL_PASSWORD

    rm -f /home/$USER_NAME/rd_xfer
    ln -s /misc/rd_xfer /home/$USER_NAME/rd_xfer
    rm -f /home/$USER_NAME/music_export
    ln -s /misc/music_export /home/$USER_NAME/music_export
    rm -f /home/$USER_NAME/music_import
    ln -s /misc/music_import /home/$USER_NAME/music_import
    rm -f /home/$USER_NAME/traffic_export
    ln -s /misc/traffic_export /home/$USER_NAME/traffic_export
    rm -f /home/$USER_NAME/traffic_import
    ln -s /misc/traffic_import /home/$USER_NAME/traffic_import
fi

if test $START_JACK = "true" ; then
    echo "UPDATE STATIONS set START_JACK='Y', JACK_COMMAND_LINE='/usr/bin/jackd --name default -d dummy -r 48000' WHERE NAME='$HOSTNAME';" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOSTNAME $MYSQL_DATABASE
fi
