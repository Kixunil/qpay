if [ -r "/usr/local/etc/qpay/target_vm" ];
then
	TARGET_VM="`cat "/usr/local/etc/qpay/target_vm"`" || exit 1
elif [ -r "/etc/qpay/target_vm" ];
then
	TARGET_VM="`cat "/etc/qpay/target_vm"`" || exit 1
else
	echo 'Error: unknown target vm' >&2
	echo 'Neither /usr/local/etc/qpay/target_vm nor /etc/qpay/target_vm could be loaded' >&2
	exit 1
fi

if [ -z "$1" ];
then
	split -e -l 1 -u --filter='qrexec-client-vm '"$TARGET_VM"' qpay'
elif [ "$1" = "--help" ] || [ "$1" = "-h" ];
then
	echo 'Qpay - safe Lightning Network payment client'
	echo
	echo 'Usage: qpay                        - pay invoices from stdin'
	echo '       qpay INVOICE [INVOICE ...]  - pay given invoice(s)'
	echo '       qpay -h|--help              - shows this message'
	echo '       qpay -q|--qr                - pay invoice(s) from qr code(s)'
	echo '       qpay -p|--primary           - pay invoice(s) in X server primary selection'
	echo '       qpay -s|--secondary         - pay invoice(s) in X server secondary selection'
	echo '       qpay -c|--clipboard         - pay invoice(s) in X server clipboard'
	echo '       qpay -b|--bridge            - launches HTTP bridge accepting invoices at localhost:9876/INVOICE'
	echo
	echo 'All commands except selections and bridge output payment preimages to stdout.'
	echo 'Selection commands overwrite the selection with preimages.'
	echo 'Bridge returns preimages in responses.'
elif [ "$1" = "--qr" ] || [ "$1" = "-q" ];
then
	zbarcam | sed -u 's/^.*://g' | split -e -l 1 -u --filter='qrexec-client-vm '"$TARGET_VM"' qpay'
elif [ "$1" = "-p" ] || [ "$1" = "--primary" ] || [ "$1" = "-s" ] || [ "$1" = "--secondary" ] || [ "$1" = "-c" ] || [ "$1" = "--clipboard" ];
then
	xsel "$1" | sed -u 's/^lightning://g' | split -e -l 1 -u --filter='qrexec-client-vm '"$TARGET_VM"' qpay' | xsel "$1" -i
elif [ "$1" = "--bridge" ] || [ "$1" = "-b" ];
then
	qpay-http-bridge "$TARGET_VM"
else
	while [ $# -gt 0 ];
	do
		echo "$1" | sed -u 's/^lightning://g' | qrexec-client-vm "$TARGET_VM" qpay
		shift
	done
fi
