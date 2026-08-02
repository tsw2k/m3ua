## configure.ac
##
## Process this file with autoconf to produce a configure script.
##
## Boilerplate:  standard boilerplate code
##
AC_INIT([m3ua], [1.3.0], [issues@sigscale.org])
AC_COPYRIGHT([Copyright (c) 2015-2025 SigScale Global Inc.])
AC_PREREQ(2.63)
AC_LANG([Erlang])
AC_CONFIG_SRCDIR([src/m3ua_app.erl])
AC_CONFIG_HEADERS([config.h])
AM_INIT_AUTOMAKE([-Wno-portability])

##
## Options:  control options to configure, support code for the options
##
AC_ARG_ENABLE([debug],
		[AS_HELP_STRING([--disable-debug], [disable debugging (default is no)])])

##
## Programs:  check for programs needed by the configure process,
##            the build process, or by one of the programs being built
##
AC_ERLANG_NEED_ERL
AC_ERLANG_NEED_ERLC
if test -z "${ERLCFLAGS}" ; then
	ERLCFLAGS="-W -v"
fi
if test "x$disable_debug" != xyes ; then
	ERLCFLAGS="$ERLCFLAGS +debug_info"
fi
AC_ERLANG_SUBST_LIB_DIR
if test -z "${ERLANG_INSTALL_LIB_DIR}" ; then
	ERLANG_INSTALL_LIB_DIR=$ERLANG_LIB_DIR
fi
AC_ERLANG_SUBST_ROOT_DIR
AC_PROG_MKDIR_P
AC_PROG_INSTALL
AC_PROG_LN_S
AC_ERLANG_SUBST_INSTALL_LIB_DIR
otpdir=$ERLANG_INSTALL_LIB_DIR/..
appdir=$ERLANG_INSTALL_LIB_DIR/$PACKAGE_NAME-$PACKAGE_VERSION
beamdir=$ERLANG_INSTALL_LIB_DIR/$PACKAGE_NAME-$PACKAGE_VERSION/ebin
emibdir=$ERLANG_INSTALL_LIB_DIR/$PACKAGE_NAME-$PACKAGE_VERSION/priv/mibs
mibsdir=$ERLANG_INSTALL_LIB_DIR/$PACKAGE_NAME-$PACKAGE_VERSION/mibs
wwwdir=$ERLANG_INSTALL_LIB_DIR/$PACKAGE_NAME-$PACKAGE_VERSION/priv/www
eincludedir=$ERLANG_INSTALL_LIB_DIR/$PACKAGE_NAME-$PACKAGE_VERSION/include
docdir=$ERLANG_INSTALL_LIB_DIR/$PACKAGE_NAME-$PACKAGE_VERSION/doc
reldir=$ERLANG_INSTALL_LIB_DIR/../releases
AC_SUBST(otpdir)
AC_SUBST(appdir)
AC_SUBST(beamdir)
AC_SUBST(emibdir)
AC_SUBST(mibsdir)
AC_SUBST(wwwdir)
AC_SUBST(eincludedir)
AC_SUBST(reldir)


##
## Libraries:  check for libraries
##
AC_ERLANG_SUBST_ERTS_VER
AC_ERLANG_CHECK_LIB([kernel], [], [AC_MSG_ERROR([kernel was not found!])])
AC_ERLANG_CHECK_LIB([stdlib], [], [AC_MSG_ERROR([stdlib was not found!])])
AC_ERLANG_CHECK_LIB([sasl], [], [AC_MSG_ERROR([sasl was not found!])])
AM_CONDITIONAL([MAKE_TAR_EXTRA_FILES],
		[AS_VERSION_COMPARE([$ERLANG_LIB_VER_sasl], ["4.0"], [false], [true], [true])])
AC_ERLANG_CHECK_LIB([mnesia], [], [AC_MSG_ERROR([mnesia was not found!])])
AC_ERLANG_CHECK_LIB([compiler], [], [AC_MSG_ERROR([compiler was not found!])])
AC_ERLANG_CHECK_LIB([inets], [], [AC_MSG_ERROR([inets was not found!])])
AC_ERLANG_CHECK_LIB([snmp], [], [AC_MSG_ERROR([snmp was not found!])])
## The MIB is compiled against the enterprise root sigscale_mibs
## carries, so that package is needed to build it -- and only to build
## it.  m3ua_mib loads an already compiled MIB at run time and the rest
## of the application never mentions it.  Where it is absent everything
## else is built, the MIB is not, and the release does not list it.
AC_ERLANG_CHECK_LIB([sigscale_mibs], [have_sigscale_mibs=yes],
		[have_sigscale_mibs=no
		AC_MSG_WARN([sigscale_mibs was not found: the SNMP MIB will not be built])])
AM_CONDITIONAL([HAVE_SIGSCALE_MIBS], [test "x$have_sigscale_mibs" = "xyes"])
AS_IF([test "x$have_sigscale_mibs" = "xyes"],
		[sigscale_mibs_rel="{sigscale_mibs, \"$ERLANG_LIB_VER_sigscale_mibs\"},"],
		[sigscale_mibs_rel=""])
AC_SUBST(sigscale_mibs_rel)


##
## Headers:  check for header files
##


##
## Typedefs & Structures:  check for typedefs, structures,
##                         and compiler characteristics.
##


##
## Functions:  check for library functions
##


##
## Output:  create output files
## 
AC_OUTPUT([Makefile include/Makefile ebin/Makefile doc/Makefile priv/Makefile
		priv/www/Makefile priv/mibs/Makefile mibs/Makefile test/Makefile
		$PACKAGE_NAME.rel ebin/$PACKAGE_NAME.appup sys.config])

