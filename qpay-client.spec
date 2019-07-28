Name:		qpay-client
Version:	0.2
Release:	1%{?dist}
Summary:	Qpay - QubesOS-based Lightning Network client

License:	MITNFA
URL:		https://github.com/Kixunil/qpay

Requires:	qubes-core-agent-qrexec
Recommends:	zbar xsel
Provides:	lightning-network-uri-handler

%description
A command line client for accessing Lightning Network wallet
in a separate Qubes OS domain from a less trusted domain. It should
be installed in all template VMs which are bases of LN-accessing
app VMs.

This package also provides an HTTP daemon which allows to access
the wallet from browser extensions using WebLN API.

%prep
mkdir -p "$RPM_BUILD_ROOT"/usr/{bin,share/applications}
mkdir -p "$RPM_BUILD_ROOT"/etc/{qpay,systemd/system}

cp ../SOURCES/qpay-client/usr/bin/* "$RPM_BUILD_ROOT/usr/bin"
cp ../SOURCES/qpay-client/usr/share/applications/* "$RPM_BUILD_ROOT/usr/share/applications/"
cp ../SOURCES/qpay-client/etc/systemd/system/* "$RPM_BUILD_ROOT/etc/systemd/system/"

exit

%files
%attr(0755, root, root) /usr/bin/*
%attr(0644, root, root) /usr/share/applications/*
%attr(0644, root, root) /etc/systemd/system/*

%changelog

