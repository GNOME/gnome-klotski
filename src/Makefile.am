bin_PROGRAMS = gnotski

gnotski_SOURCES = \
	gnotski.c	\
	pieces.h

gnotski_CPPFLAGS = \
	-I$(top_srcdir) \
	$(AM_CPPFLAGS)

gnotski_CFLAGS = \
	$(GTK_CFLAGS)	\
	$(AM_CFLAGS)
		
gnotski_LDADD = \
	$(top_builddir)/libgames-support/libgames-support.la \
	$(GTK_LIBS)	\
	$(INTLLIBS)

if HAVE_GNOME
gnotski_CFLAGS += $(GNOME_CFLAGS)
gnotski_LDADD += $(GNOME_LIBS)
endif

if HAVE_RSVG
gnotski_CFLAGS += $(RSVG_CFLAGS)
gnotski_LDADD += $(RSVG_LIBS)
endif

if WITH_GTHREAD
gnotski_CFLAGS += $(GHTREAD_CFLAGS)
gnotski_LDADD += $(GTHREAD_LIBS)
endif

install-exec-hook:
	-if test "$(setgid)" = "true"; then \
	  chgrp $(scores_group) $(DESTDIR)$(bindir)/gnotski && chmod 2555 $(DESTDIR)$(bindir)/gnotski ;\
	fi

-include $(top_srcdir)/git.mk
