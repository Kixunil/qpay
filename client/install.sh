#!/bin/bash

if [ "$#" -lt 2 ];
then
	echo "Usage ./install.sh appvm|template TARGET_VM"
	exit 1
elif [ "$1" = appvm ];
then
	sudo mkdir -p /usr/local/{etc/qpay,bin}
	echo -n "$2" | sudo tee /usr/local/etc/qpay/target_vm >/dev/null
	sudo cp qpay.sh /usr/local/bin/qpay
	sudo cp bridge.py /usr/local/bin/qpay-http-bridge
	sudo chmod 755 /usr/local/bin/qpay /usr/local/bin/qpay-http-bridge

	echo 'qpay -b >/dev/null 2>/dev/null &' >> /rw/config/rc.local
	qpay -b >/dev/null 2>/dev/null &

	if which apt-get > /dev/null;
	then
		which zbarcam > /dev/null || echo 'Warning: zbarcam missing. Install it in templatevm using sudo apt-get install zbar-tools'
		which xsel > /dev/null || echo 'Warning: xsel missing. Install it in templatevm using sudo apt-get install xsel'
	else
		which zbarcam > /dev/null || echo 'Warning: zbarcam missing. Install it in templatevm using sudo dnf install zbar'
		which xsel > /dev/null || echo 'Warning: xsel missing. Install it in templatevm using sudo dnf install xsel'
	fi
elif [ "$1" = template ];
then
	sudo mkdir -p /etc/qpay
	echo -n "$2" | sudo tee /etc/qpay/target_vm >/dev/null
	sudo cp qpay.sh /usr/local.orig/bin/qpay
	sudo cp bridge.py /usr/local.orig/bin/qpay-http-bridge
	sudo cp bridge.service /etc/systemd/system/qpay-http-bridge.service
	sudo chmod 755 /usr/local.orig/bin/qpay /usr/local.orig/bin/qpay-http-bridge
	sudo chmod 644 /etc/systemd/system/qpay-http-bridge.service

	sudo systemctl enable qpay-http-bridge.service

	if which apt-get > /dev/null;
	then
		sudo apt-get install zbar-tools xsel
	else
		sudo dnf install zbar xsel
	fi
else
	echo "Invalid argument: $1"
	exit 1
fi
