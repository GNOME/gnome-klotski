


pixmapdir=$(datadir)/pixmaps
Gamesdir=$(datadir)/applications

SUBDIRS = help

INCLUDES = 			\
	$(GNOME_GAMES_CFLAGS)		\
	-DGNOMELOCALEDIR=\""$(datadir)/locale"\" \
	-DDATADIR=\""$(datadir)"\"		   \
	-DG_DISABLE_DEPRECATED -DGDK_DISABLE_DEPRECATED \
	-DGTK_DISABLE_DEPRECATED -DGNOME_DISABLE_DEPRECATED

bin_PROGRAMS = gnotski

gnotski_SOURCES =	\
	gnotski.c \
	pieces.h

gnotski_LDADD = \
	$(GNOME_GAMES_LIBS) \
	$(INTLLIBS) 

pixmap_DATA = gnotski.png gnotski-icon.png

Games_in_files = gnotski.desktop.in
Games_DATA = $(Games_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

EXTRA_DIST = README $(Games_in_files) $(pixmap_DATA)

CLEANFILES = $(Games_DATA)

SCOREFILES = 1 2 3 4 5 6 7 11 12 13 14 15 16 17 21 22 23 24 25 26

install-data-local:
	-$(mkinstalldirs) $(DESTDIR)$(scoredir)
	-if test "x$(setgid)" = "xtrue"; then chgrp $(scores_group) $(DESTDIR)$(bindir)/gnotski && chmod 2555 $(DESTDIR)$(bindir)/gnotski ; fi
	-for i in ${SCOREFILES} ; do \
	  touch             $(DESTDIR)$(scoredir)/gnotski.$$i.scores; \
	  chown $(scores_user):$(scores_group) $(DESTDIR)$(scoredir)/gnotski.$$i.scores; \
	  chmod 664         $(DESTDIR)$(scoredir)/gnotski.$$i.scores; \
	done
