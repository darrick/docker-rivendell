#! /bin/bash
export CONSOLE_FD
exec {CONSOLE_FD}<> /dev/console
exec echo "HOSTNAME=\"$(hostname -f)\"" > /etc/sysconfig/network
exec /usr/sbin/init
