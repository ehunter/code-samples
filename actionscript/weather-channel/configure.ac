dnl -*- mode: m4 -*-
AC_PREREQ(2.59)

AC_INIT(weather-channel, 0.4.2+big0.2.0)
APIVERSION=3

AM_INIT_AUTOMAKE([1.9 foreign tar-ustar])

AM_MAINTAINER_MODE

AC_PATH_PROG(ANT, 'ant')
test "x$ANT" != x || AC_MSG_ERROR([ant not found])

AC_PATH_PROG(UNZIP, 'unzip')
test "x$UNZIP" != x || AC_MSG_ERROR([unzip not found])

AC_PATH_PROG(SHA1SUM, 'sha1sum')
test "x$SHA1SUM" != x || AC_MSG_ERROR([sha1sum not found])

PKG_CHECK_EXISTS([adobe-flex-sdk], [LITL_FLEX_HOME="`$PKG_CONFIG --variable=sdkdir adobe-flex-sdk`"])
AC_SUBST(LITL_FLEX_HOME)

sdkcorepkg=as3-sdk-core-${APIVERSION}
sdkcontrolspkg=as3-sdk-controls-${APIVERSION}
sdkhelperspkg=as3-sdk-helpers-${APIVERSION}

PKG_CHECK_EXISTS([${sdkcorepkg}], [],
                 [AC_MSG_ERROR([pkg-config module '${sdkcorepkg}' not found])])
SDKCOREDIR="`$PKG_CONFIG --variable=coredir ${sdkcorepkg}`"
AC_SUBST(SDKCOREDIR)

PKG_CHECK_EXISTS([${sdkcontrolspkg}], [],
                 [AC_MSG_ERROR([pkg-config module '${sdkcontrolspkg}' not found])])
SDKCONTROLSDIR="`$PKG_CONFIG --variable=controlsdir ${sdkcontrolspkg}`"
AC_SUBST(SDKCONTROLSDIR)

PKG_CHECK_EXISTS([${sdkhelperspkg}], [],
                 [AC_MSG_ERROR([pkg-config module '${sdkhelperspkg}' not found])])
SDKHELPERSDIR="`$PKG_CONFIG --variable=helpersdir ${sdkhelperspkg}`"
AC_SUBST(SDKHELPERSDIR)

AC_CONFIG_FILES([
Makefile
])

AC_OUTPUT

dnl ==========================================================================
echo "

        litl weather channel $VERSION
	==================

        prefix:                     ${prefix}

        Now type 'make' to build $PACKAGE
"
