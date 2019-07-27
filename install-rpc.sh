#!/bin/bash

if [ $# -lt 2 ];
then
	echo "Usage: install-rpc.sh HOST ADMIN_MACAROON_FILE"
	exit 1
fi

mkdir -p /usr/local/etc/qubes-rpc || exit 2
cp qpay-rpc.py /usr/local/etc/qubes-rpc/qpay || exit 2
mkdir -p /usr/local/etc/qpay || exit 2
cp "$2" /usr/local/etc/qpay/admin.macaroon || exit 2
echo '{ "url": "'"$1"'" }' > /usr/local/etc/qpay/qpay.conf
