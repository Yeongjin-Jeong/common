dnl Perform a check for a feature for GStreamer
dnl Richard Boulton <richard-alsa@tartarus.org>
dnl Thomas Vander Stichele <thomas@apestaart.org> added useful stuff
dnl Last modification: 25/06/2001
dnl GST_CHECK_FEATURE(FEATURE-NAME, FEATURE-DESCRIPTION,
dnl                   DEPENDENT-PLUGINS, TEST-FOR-FEATURE,
dnl                   DISABLE-BY-DEFAULT, ACTION-IF-USE, ACTION-IF-NOTUSE)
dnl
dnl This macro adds a command line argument to enable the user to enable
dnl or disable a feature, and if the feature is enabled, performs a supplied
dnl test to check if the feature is available.
dnl
dnl The test should define HAVE_<FEATURE-NAME> to "yes" or "no" depending
dnl on whether the feature is available.
dnl
dnl The macro will set USE_<FEATURE-NAME> to "yes" or "no" depending on
dnl whether the feature is to be used.
dnl Thomas changed this, so that when USE_<FEATURE-NAME> was already set
dnl to no, then it stays that way.
dnl
dnl The macro will call AM_CONDITIONAL(USE_<<FEATURE-NAME>, ...) to allow
dnl the feature to control what is built in Makefile.ams.  If you want
dnl additional actions resulting from the test, you can add them with the
dnl ACTION-IF-USE and ACTION-IF-NOTUSE parameters.
dnl 
dnl FEATURE-NAME        is the name of the feature, and should be in
dnl                     purely upper case characters.
dnl FEATURE-DESCRIPTION is used to describe the feature in help text for
dnl                     the command line argument.
dnl DEPENDENT-PLUGINS   lists any plugins which depend on this feature.
dnl TEST-FOR-FEATURE    is a test which sets HAVE_<FEATURE-NAME> to "yes"
dnl                     or "no" depending on whether the feature is
dnl                     available.
dnl DISABLE-BY-DEFAULT  if "disabled", the feature is disabled by default,
dnl                     if any other value, the feature is enabled by default.
dnl ACTION-IF-USE       any extra actions to perform if the feature is to be
dnl                     used.
dnl ACTION-IF-NOTUSE    any extra actions to perform if the feature is not to
dnl                     be used.
dnl
dnl
dnl thomas :
dnl we also added a history.  
dnl GST_PLUGINS_YES will contain all plugins to be built
dnl                 that were checked through GST_CHECK_FEATURE
dnl GST_PLUGINS_NO will contain those that won't be built

AC_DEFUN(GST_CHECK_FEATURE,
[dnl
builtin(define, [gst_endisable], ifelse($5, [disabled], [enable], [disable]))dnl
dnl if it is set to NO, then don't even consider it for building
NOUSE=
if test "x$USE_[$1]" = "xno"; then
  NOUSE="yes"
fi
AC_ARG_ENABLE(translit([$1], A-Z, a-z),
  [  ]builtin(format, --%-26s gst_endisable %s, gst_endisable-translit([$1], A-Z, a-z), [$2]ifelse([$3],,,: [$3])),
  [ case "${enableval}" in
      yes) USE_[$1]=yes;;
      no) USE_[$1]=no;;
      *) AC_MSG_ERROR(bad value ${enableval} for --enable-translit([$1], A-Z, a-z)) ;;
    esac],
  [ USE_$1=]ifelse($5, [disabled], [no], [yes]))           dnl DEFAULT

dnl *** set it back to no if it was preset to no
if test "x$NOUSE" = "xyes"; then
  USE_[$1]="no"
  AC_MSG_WARN(*** $3 pre-configured not to be built)
fi
NOUSE=

dnl *** If it's enabled

if test x$USE_[$1] = xyes; then
  dnl save compile variables before the test

  gst_check_save_LIBS=$LIBS
  gst_check_save_LDFLAGS=$LDFLAGS
  gst_check_save_CFLAGS=$CFLAGS
  gst_check_save_CPPFLAGS=$CPPFLAGS
  gst_check_save_CXXFLAGS=$CXXFLAGS

  HAVE_[$1]=no
  dnl TEST_FOR_FEATURE
  $4

  LIBS=$gst_check_save_LIBS
  LDFLAGS=$gst_check_save_LDFLAGS
  CFLAGS=$gst_check_save_CFLAGS
  CPPFLAGS=$gst_check_save_CPPFLAGS
  CXXFLAGS=$gst_check_save_CXXFLAGS

  dnl If it isn't found, unset USE_[$1]
  if test x$HAVE_[$1] = xno; then
    USE_[$1]=no
  fi
fi
dnl *** Warn if it's disabled or not found
if test x$USE_[$1] = xyes; then
  ifelse([$6], , :, [$6])
  if test "x$3" != "x"; then
    GST_PLUGINS_YES="\t[$3]\n$GST_PLUGINS_YES"
  fi
  AC_DEFINE(HAVE_[$1], , [support for features: $3])
else
  ifelse([$3], , :, [AC_MSG_NOTICE(*** These plugins will not be built: [$3])])
  if test "x$3" != "x"; then
    GST_PLUGINS_NO="\t[$3]\n$GST_PLUGINS_NO"
  fi
  ifelse([$7], , :, [$7])
fi
dnl *** Define the conditional as appropriate
AM_CONDITIONAL(USE_[$1], test x$USE_[$1] = xyes)
])

dnl Use a -config program which accepts --cflags and --libs parameters
dnl to set *_CFLAGS and *_LIBS and check existence of a feature.
dnl Richard Boulton <richard-alsa@tartarus.org>
dnl Last modification: 26/06/2001
dnl GST_CHECK_CONFIGPROG(FEATURE-NAME, CONFIG-PROG-FILENAME, MODULES)
dnl
dnl This check was written for GStreamer: it should be renamed and checked
dnl for portability if you decide to use it elsewhere.
dnl
AC_DEFUN(GST_CHECK_CONFIGPROG,
[
  AC_PATH_PROG([$1]_CONFIG, [$2], no)
  if test x$[$1]_CONFIG = xno; then
    [$1]_LIBS=
    [$1]_CFLAGS=
    HAVE_[$1]=no
  else
    [$1]_LIBS=`[$2] --libs [$3]`
    [$1]_CFLAGS=`[$2] --cflags [$3]`
    HAVE_[$1]=yes
  fi
  AC_SUBST([$1]_LIBS)
  AC_SUBST([$1]_CFLAGS)
])

dnl Use AC_CHECK_LIB and AC_CHECK_HEADER to do both tests at once
dnl sets HAVE_module if we have it
dnl Richard Boulton <richard-alsa@tartarus.org>
dnl Last modification: 26/06/2001
dnl GST_CHECK_LIBHEADER(FEATURE-NAME, LIB NAME, LIB FUNCTION, EXTRA LD FLAGS, 
dnl                     HEADER NAME, ACTION-IF-FOUND, ACTION-IF-NOT-FOUND)
dnl
dnl This check was written for GStreamer: it should be renamed and checked
dnl for portability if you decide to use it elsewhere.
dnl
AC_DEFUN(GST_CHECK_LIBHEADER,
[
  AC_CHECK_LIB([$2], [$3], HAVE_[$1]=yes, HAVE_[$1]=no,[$4])
  if test "x$HAVE_[$1]" = "xyes"; then
    AC_CHECK_HEADER([$5], :, HAVE_[$1]=no)
    if test "x$HAVE_[$1]" = "xyes"; then
      dnl execute what needs to be
      ifelse([$6], , :, [$6])
    else
      ifelse([$7], , :, [$7])
    fi
  else
    ifelse([$7], , :, [$7])
  fi
  AC_SUBST(HAVE_[$1])
]
)

dnl 2003-06-27 Benjamin Otte - make this work with gstconfig.h
dnl
dnl Add a subsystem --disable flag and all the necessary symbols and substitions
dnl
dnl GST_SUBSYSTEM_DISABLE(SYSNAME, [subsystem name])
dnl
AC_DEFUN(GST_SUBSYSTEM_DISABLE,
[AC_ARG_ENABLE(translit([$1], A-Z, a-z), 
[  ]builtin(format, --disable-%-17s  disable %s, translit([$1], A-Z, a-z), $2),
[ case "${enableval}" in
    yes) GST_DISABLE_[$1]=no ;;
    no) GST_DISABLE_[$1]=yes ;;
    *) AC_MSG_ERROR(bad value ${enableval} for --enable-translit([$1], A-Z, a-z)) ;;
  esac],
[GST_DISABLE_[$1]=no]) dnl Default value
if test x$GST_DISABLE_[$1] = xyes; then
  GST_DISABLE_[$1]_DEFINE="#define GST_DISABLE_$1 1" 
else
  GST_DISABLE_[$1]_DEFINE="/* #undef GST_DISABLE_$1 */"
fi
AM_CONDITIONAL(GST_DISABLE_[$1], test x$GST_DISABLE_[$1] = xyes)
AC_SUBST(GST_DISABLE_[$1]_DEFINE)
])

