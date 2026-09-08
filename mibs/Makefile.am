## Makefile.am
## vim: ts=3
##
## Process this file with automake to produce Makefile.in

mibs_DATA = MTXC-SMI.mib MTXC-M3UA-MIB.mib

check_DATA = .tree_ok

.tree_ok:
	@if snmptranslate -V > /dev/null 2>&1; then \
		snmptranslate -M +$(top_srcdir)/mibs \
			-m +MTXC-M3UA-MIB -Lo -Tp -IR m3uaMIB; \
	fi

