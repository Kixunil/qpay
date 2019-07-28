#!/bin/bash

if [ "$#" -lt 1 ];
then
	echo "Usage ./install.sh template|(appvm TARGET_VM)"
	exit 1
elif [ "$1" = appvm ];
then
	if [ -n "$2" ];
	then
		echo "Usage ./install.sh template|(appvm TARGET_VM)"
		exit 1
	fi

	sudo mkdir -p /usr/local/{etc/qpay,bin,share/applications}
	echo -n "$2" | sudo tee /usr/local/etc/qpay/target_vm >/dev/null
	sudo cp qpay-client_0.2-1/usr/bin/* /usr/local/bin/
	sudo chmod 755 /usr/local/bin/qpay /usr/local/bin/qpay-http-bridge
	sudo cp qpay-client_0.2-1/usr/share/applications/* /usr/local/share/applications/
	sudo update-desktop-database /usr/local/share/applications

	echo 'qpay -b >/dev/null 2>/dev/null &' >> /rw/config/rc.local
	qpay -b >/dev/null 2>/dev/null &

	if which apt-get &> /dev/null;
	then
		which zbarcam &> /dev/null || echo 'Warning: zbarcam missing. Install it in templatevm using sudo apt-get install zbar-tools'
		which xsel &> /dev/null || echo 'Warning: xsel missing. Install it in templatevm using sudo apt-get install xsel'
	else
		which zbarcam &> /dev/null || echo 'Warning: zbarcam missing. Install it in templatevm using sudo dnf install zbar'
		which xsel &> /dev/null || echo 'Warning: xsel missing. Install it in templatevm using sudo dnf install xsel'
	fi
elif [ "$1" = template ];
then
	if which dpkg &> /dev/null;
	then
		# Yep, it's that simple!
		fakeroot sh -c 'chown -R root qpay-client_0.2-1 && dpkg-deb --build qpay-client_0.2-1'
		sudo dpkg -i qpay-client_0.2-1.deb
		sudo apt-get -f install
	else
		if which rpmbuild &> /dev/null;
		then
			REMOVE_RPMBUILD=0
		else
			REMOVE_RPMBUILD=1
			sudo dnf install -y rpm-build || exit 1
		fi

		BUILDDIR="`mktemp -d`"

		mkdir -p "$BUILDDIR/rpmbuild/"{RPMS/noarch,SOURCES,SPECS,SRPMS}
		ln -s $PWD/qpay-client.spec "$BUILDDIR/rpmbuild/SPECS/"
		ln -s $PWD/qpay-client_0.2-1 "$BUILDDIR/rpmbuild/SOURCES/qpay-client"
		HOME=$BUILDDIR rpmbuild -bb --target noarch qpay-client.spec
		sudo rpm -i "$BUILDDIR/rpmbuild/RPMS/noarch/qpay-client-0.2-1*.rpm"
		sudo rm -rf "$BUILDDIR"

		echo "Enter the name of Qubes domain providing qpay RPC"
		echo "(VM runing Lightning node or used to connect to a remote one)"
		read TARGET_VM
		sudo mkdir -p /etc/qpay
		echo -n "$TARGET_VM" | sudo tee /etc/qpay/target_vm > /dev/null

		test $REMOVE_RPMBUILD -eq 1 && sudo dnf remove -y rpmbuild
	fi
else
	echo "Invalid argument: $1"
	exit 1
fi
