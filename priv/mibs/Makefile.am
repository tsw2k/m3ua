## Makefile.am
## vim: ts=3
##
## Process this file with automake to produce Makefile.in

ERLCFLAGS =  +'{group_check, false}'

## Built only where sigscale_mibs is installed: the MIB imports the
## enterprise root from it and erlc cannot resolve that without it.
if HAVE_SIGSCALE_MIBS
emib_DATA =  SIGSCALE-M3UA-MIB.bin
else
emib_DATA =
endif

%.bin:$(top_srcdir)/mibs/%.mib $(top_srcdir)/mibs/%.funcs
	$(ERLC) $(ERLCFLAGS) -I $(ERLANG_LIB_DIR_sigscale_mibs)/priv/mibs -I $(ERLANG_LIB_DIR_snmp)/priv/mib $<

CLEANFILES = SIGSCALE-M3UA-MIB.bin

