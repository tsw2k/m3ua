## Makefile.am
## vim: ts=3
##
## Process this file with automake to produce Makefile.in

ERLCFLAGS =  +'{group_check, false}'

emib_DATA =  MTXC-SMI.bin MTXC-M3UA-MIB.bin

# MTXC-SMI has no .funcs: it registers object identities and nothing
# instrumented, so it is built from the .mib alone. -I finds our own
# compiled SMI, which is why the SMI must be built first.
MTXC-SMI.bin:$(top_srcdir)/mibs/MTXC-SMI.mib
	$(ERLC) $(ERLCFLAGS) -I $(ERLANG_LIB_DIR_snmp)/priv/mib $<

MTXC-M3UA-MIB.bin:$(top_srcdir)/mibs/MTXC-M3UA-MIB.mib \
		$(top_srcdir)/mibs/MTXC-M3UA-MIB.funcs MTXC-SMI.bin
	$(ERLC) $(ERLCFLAGS) -I . -I $(ERLANG_LIB_DIR_snmp)/priv/mib \
		$(top_srcdir)/mibs/MTXC-M3UA-MIB.mib

CLEANFILES = $(emib_DATA)

