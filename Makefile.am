scoredir=$(localstatedir)/games
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

install-data-local:
	-$(mkinstalldirs) $(DESTDIR)$(scoredir)
	-chgrp games $(DESTDIR)$(bindir)/gnotski && chmod 2555 $(DESTDIR)$(bindir)/gnotski
	-touch             $(DESTDIR)$(scoredir)/gnotski.1.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.1.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.1.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.2.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.2.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.2.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.3.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.3.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.3.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.4.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.4.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.4.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.5.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.5.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.5.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.6.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.6.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.6.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.7.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.7.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.7.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.11.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.11.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.11.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.12.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.12.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.12.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.13.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.13.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.13.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.14.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.14.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.14.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.15.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.15.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.15.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.16.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.16.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.16.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.17.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.17.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.17.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.21.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.21.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.21.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.22.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.22.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.22.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.23.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.23.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.23.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.24.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.24.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.24.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.25.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.25.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.25.scores
	-touch             $(DESTDIR)$(scoredir)/gnotski.26.scores
	-chown games.games $(DESTDIR)$(scoredir)/gnotski.26.scores
	-chmod 664         $(DESTDIR)$(scoredir)/gnotski.26.scores
