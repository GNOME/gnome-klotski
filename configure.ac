AC_INIT(gnome-klotski, 3.7.0)
AM_INIT_AUTOMAKE([1.11 no-dist-gzip dist-xz foreign])
AM_SILENT_RULES([yes])
AM_MAINTAINER_MODE
GNOME_MAINTAINER_MODE_DEFINES
AC_CONFIG_HEADERS([config.h])

AM_PROG_CC_C_O

GLIB_GSETTINGS

dnl ###########################################################################
dnl setgid checks
dnl ###########################################################################

AC_ARG_ENABLE([setgid],
  [AS_HELP_STRING([--disable-setgid],
    [Disable the use of setgid binaries])],
  [case "${enableval}" in
    yes) setgid=true ;;
    no)  setgid=false ;;
    *) AC_MSG_ERROR([bad value ${enableval} for --disable-setgid]) ;;
   esac],
  [if test "$platform_win32" = "yes"; then
     enable_setgid=no
     setgid=false
   else
     enable_setgid=yes
     setgid=true
   fi])

scoredir='${localstatedir}/games'
scores_group=games
scores_user=games

if test "$enable_setgid" = "yes"; then
  AC_DEFINE([ENABLE_SETGID],[1],[Define if use of setgid binaries is enabled])

  AC_ARG_WITH(scores-group,
    AS_HELP_STRING([--with-scores-group=group],
      [Group for the high score tables and binaries]),
    scores_group="$withval",scores_group="games")
  AC_ARG_WITH(scores-user,
    AS_HELP_STRING([--with-scores-user=user],
      [User for the high score tables]),
    scores_user="$withval",scores_user="games")
fi

AM_CONDITIONAL([ENABLE_SETGID],[test "$enable_setgid" = "yes"])

AC_SUBST(setgid)
AC_SUBST(scores_group)
AC_SUBST(scores_user)
AC_SUBST(scoredir)

dnl ###########################################################################
dnl Dependencies
dnl ###########################################################################

GTK_REQUIRED=3.4.0
RSVG_REQUIRED=2.32.0

PKG_CHECK_MODULES(GNOME_KLOTSKI, [
  gtk+-3.0 >= $GTK_REQUIRED
  librsvg-2.0 >= $RSVG_REQUIRED
])

dnl ###########################################################################
dnl Internationalization
dnl ###########################################################################

IT_PROG_INTLTOOL([0.35.0])
AC_SUBST(GETTEXT_PACKAGE, gnome-klotski)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE", [The gettext package name])

dnl ###########################################################################
dnl Documentation
dnl ###########################################################################

YELP_HELP_INIT

dnl ###########################################################################
dnl Files to generate
dnl ###########################################################################

AC_OUTPUT([
Makefile
po/Makefile.in
data/Makefile
data/icons/Makefile
data/gnome-klotski.desktop.in
help/Makefile
src/Makefile
])
