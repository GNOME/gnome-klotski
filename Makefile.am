


pixmapdir=$(datadir)/pixmaps
Gamesdir=$(datadir)/applications

schemadir   = @GCONF_SCHEMA_FILE_DIR@
schema_in_files = gnotski.schemas.in
schema_DATA = $(schema_in_files:.schemas.in=.schemas)
@INTLTOOL_SCHEMAS_RULE@

SUBDIRS = help

INCLUDES = 			\
	$(GNOME_GAMES_CFLAGS)		\
	-DGNOMELOCALEDIR=\""$(datadir)/locale"\" \
	-DDATADIR=\""$(datadir)"\"

bin_PROGRAMS = gnotski

gnotski_SOURCES =	\
	gnotski.c \
	pieces.h

gnotski_LDADD = \
	$(GNOME_GAMES_LIBS) \
	$(INTLLIBS) 

pixmap_DATA = gnotski.svg gnotski-icon.png

Games_in_files = gnotski.desktop.in
Games_DATA = $(Games_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

EXTRA_DIST = README $(Games_in_files) $(pixmap_DATA)

CLEANFILES = $(Games_DATA)

SCOREFILES = 1 2 3 4 5 6 7 11 12 13 14 15 16 17 21 22 23 24 25 26

install-data-local:
if GCONF_SCHEMAS_INSTALL
        GCONF_CONFIG_SOURCE=$(GCONF_SCHEMA_CONFIG_SOURCE) $(GCONFTOOL) --makefile-install-rule $(top_builddir)/gnotski/$(schema_DATA)
endif
	-$(mkinstalldirs) $(DESTDIR)$(scoredir)
	-if test "x$(setgid)" = "xtrue"; then chgrp $(scores_group) $(DESTDIR)$(bindir)/gnotski && chmod 2555 $(DESTDIR)$(bindir)/gnotski ; fi
	-for i in ${SCOREFILES} ; do \
	  touch             $(DESTDIR)$(scoredir)/gnotski.$$i.scores; \
	  chown $(scores_user):$(scores_group) $(DESTDIR)$(scoredir)/gnotski.$$i.scores; \
	  chmod 664         $(DESTDIR)$(scoredir)/gnotski.$$i.scores; \
	done

DISTCLEANFILES = $(Games_DATA) $(schema_DATA)
