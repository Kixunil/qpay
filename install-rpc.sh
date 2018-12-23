#!/bin/bash

if [ $# -lt 2 ];
then
	echo "Usage: install-rpc.sh HOST ADMIN_MACAROON_FILE"
	exit 1
fi

cp qpay-rpc.py /etc/qubes-rpc/qpay || exit 2
mkdir -p /etc/qpay || exit 2
cp "$2" /etc/qpay/admin.macaroon || exit 2
echo '{ "url": "'"$1"'" }' > /etc/qpay/qpay.conf
