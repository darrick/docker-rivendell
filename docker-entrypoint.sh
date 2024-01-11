#!/bin/sh
set -eo pipefail
shopt -s nullglob

# USAGE: AddDbUser <dbname> <hostname> <username> <password>
function AddDbUser {
    echo "CREATE USER IF NOT EXISTS '${3}'@'${2}' IDENTIFIED BY '${4}';" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST
    echo "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON ${1}.* TO '${3}'@'${2}';" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST
    echo "FLUSH PRIVILEGES;" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOST
}

function GenerateDefaultRivendellConfiguration {
    mkdir -p /etc/rivendell.d
    cat /usr/share/rhel-rivendell-installer/rd.conf-sample | sed s/%MYSQL_HOSTNAME%/$MYSQL_HOSTNAME/g | sed s/%MYSQL_LOGINNAME%/$MYSQL_LOGINNAME/g | sed s/%MYSQL_PASSWORD%/$MYSQL_PASSWORD/g | sed s^%NFS_MOUNT_SOURCE%^$NFS_MOUNT_SOURCE^g | sed s/%NFS_MOUNT_TYPE%/$NFS_MOUNT_TYPE/g > /etc/rivendell.d/rd-default.conf
    ln -s -f /etc/rivendell.d/rd-default.conf /etc/rd.conf
}

function CreateDefaultRivendellDatabase {

		declare -g DATABASE_ALREADY_EXISTS

		if mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOSTNAME -e "use $MYSQL_DB"; then
    		DATABASE_ALREADY_EXISTS="true"
    		echo "Database $MYSQL_DB already exists.";
		fi

		#
		# Create Rivendell Database
		#
		if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
    		echo "CREATE DATABASE $MYSQL_DB;" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOSTNAME
    		AddDbUser $MYSQL_DB "%" $MYSQL_LOGINNAME $MYSQL_PASSWORD
				echo "Creating $MYSQL_DB database"
    		rddbmgr --create --generate-audio
    		echo "UPDATE STATIONS set START_JACK='Y', JACK_COMMAND_LINE='/usr/bin/jackd --name default -d dummy -r 48000' WHERE NAME='rivendell';" | mysql -u $MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD -h $MYSQL_HOSTNAME $MYSQL_DB
		fi
}

declare -g USER_NAME_ALREADY_EXISTS

function CreateDefaultRivendellUser {
	if id $USER_NAME >> /dev/null; then
    USER_NAME_ALREADY_EXISTS="true"
	else
    adduser -c Rivendell\ Audio --groups audio,wheel $USER_NAME && echo $USER_NAME:$USER_PASSWORD | chpasswd
	fi
}

# Wait for database to come online.
while ! nc -z $MYSQL_HOST 3306; do sleep 1; done

GenerateDefaultRivendellConfiguration
CreateDefaultRivendellUser

if test $MODE = "server" ; then
    #
    # Initialize Automounter
    #
    cp /etc/auto.misc /etc/auto.misc-original
    cp -f /usr/share/rhel-rivendell-installer/auto.misc.template /etc/auto.misc
    systemctl enable autofs

    #
    # Create Rivendell Database
    #
    CreateDefaultRivendellDatabase

    #
    # Create common directories
    #
		if [ -z "$USER_NAME_ALREADY_EXISTS" ]; then

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
fi

if test $MODE = "client" ; then
    #
    # Initialize Automounter
    #
    rm -f /etc/auto.rd.audiostore
    cat /usr/share/rhel-rivendell-installer/auto.rd.audiostore.template | sed s/@IP_ADDRESS@/$NFS_HOSTNAME/g > /etc/auto.rd.audiostore

		if [ -z "$USER_NAME_ALREADY_EXISTS" ]; then
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
    rm -f /etc/auto.misc
		fi
    cat /usr/share/rhel-rivendell-installer/auto.misc.client_template | sed s/@IP_ADDRESS@/$NFS_HOSTNAME/g > /etc/auto.misc
    systemctl enable autofs
fi

exec /usr/sbin/init

