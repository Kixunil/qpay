#!/bin/bash

if [ $# -lt 1 ];
then
	echo "Usage: install-rpc.sh lnd-http HOST ADMIN_MACAROON_FILE"
	echo "Usage: install-rpc.sh eclair [PORT]"
	exit 1
fi

mkdir -p /usr/local/etc/qubes-rpc || exit 2
cp qpay-rpc.py /usr/local/etc/qubes-rpc/qpay || exit 2
mkdir -p /usr/local/etc/qpay || exit 2

if [ "$1" = 'lnd-http' ];
then
	cp "$3" /usr/local/etc/qpay/admin.macaroon || exit 2
	echo '{ "backend": "lnd-http", "url": "'"$2"'" }' > /usr/local/etc/qpay/qpay.conf
elif [ "$1" = 'eclair' ];
then
	if [ -n "$2" ];
	then
		PORT="$2"
	else
		PORT=8080
	fi

	echo Enter Eclair RPC password
	read -s PASSWORD

	# While echoing passwords isn't safe, it's OK in trusted Qubes VM
	# because other programs have access to the file anyway.
	# Why not accept the password as an argument? To avoid accidental leaks
	# from history.
	echo '{ "backend": "eclair", "password": "'"$PASSWORD"'" }' > /usr/local/etc/qpay/qpay.conf
else
	echo 'Invalid backend' >&2
fi
