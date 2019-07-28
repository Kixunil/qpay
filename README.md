Qpay
====

QubesOS - optimized Lightning Network payment dialog

About
-----

If you tried Joule, you might find it cool, but if you're also security-minded
person using QubesOS, you probably see the glaring security hole: you must
install it together with admin macaroon into every domain you wish to pay from.
So if any of the domains is exploited, your money will be stolen.

Can we do any better? Yes, we can!

This tool consists of four parts:

* qpay - Qubes RPC server
* QubesOS policy - policy to install into dom0
* Bridge script - a simple server that turns HTTP requests into Qubes RPC calls
* Firefox extension - extension bringing Joule-like experience to qpay!

This tool makes sure only one (trusted) VM, let's call it lightningvm, has your
macaroon and provides other VMs to request payments. When payment request is
initiated, the lightningvm shows a simple dialog asking whether you want to
perform the payment. This way no other VM can force you to spend money you don't want.

Considering that there are **currently** no HW wallets for Lightning and all other approaches don't use Qubes, this is **possibly** the most secure Lightning Network "wallet" available, **assuming no security bugs in qpay itself**!

How to use
----------

**Please carefuly review the code before use! It's not too long.**

In order to use this tool, you need to install Qubes RPC server into the lightningvm - the VM you use to manage your remote node or run your local node (since if that is compromised, you have the exact same problem as if you had qpay compromised). A *very* simple install script (`install-rpc.sh`) is provided to do this.

Then you need to create policy file in `dom0` - see `policy-example`.

After that, you must install qpay command and bridge script (found in `client/bridge`) into every VM you want to use the extension from. Installing it into template VM is quicker.

An installation script (`install-client.sh`) is provided to help with client installation. It's somewhat longer but handles both app VM and template VM for Fedora and Debian templates. In case of templates it builds and installs native package. This ensures easy removal, minimizes configuration steps and allows registering `lightning:` URI handler.

Finally you need to install the extension. Right now, the extension isn't
published, so you have to use temporary loading in `about:debugging`. Sorry.

The extension partially implements WebLN API.

Security considerations
-----------------------

In order for the tool to be as secure as reasonably possible, these things were
considered:

 * The code needs to be as simple as possible
 * Ideally no dependencies that aren't installed on Qubes already
 * Performance isn't too important - safety is
 * The code should be easily auditable

Conclusion from above: use Python with Gtk and avoid adding too many features.

There's also no need to encrypt admin macaroon, since Qubes has FDE by default
and if someone manages to backdoor your VM, you're already screwed.

Disclaimer
----------

This software is provided "AS IS" without any guarantees of being secure,
working as expected or being fit for any purpose. The author isn't responsible
for any damage, directly or indirectly caused by use of this software!

The author reserves the right to *publicly* ridicule you for running this
softwre without proper review by yourself or a well-skilled security consultant.

If you don't agree to these terms DON'T use this software!

If you agree to these terms, the software is freely available to you and you may modify or share it (modified or not) as you wish. You are forbidden from
falsely attributing your changes to the author of the code or falsely
attributing the authorship of the code to yourself!

Author
------

Martin Habovstiak
