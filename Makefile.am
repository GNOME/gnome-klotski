scoredir=$(DESTDIR)$(localstatedir)/games
pixmapdir=$(datadir)/pixmaps
Gamesdir=$(datadir)/applications

INCLUDES = 			\
	$(GNOME_GAMES_CFLAGS)		\
	-DGNOMELOCALEDIR=\""$(datadir)/locale"\" \
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

EXTRA_DIST = README gnotski.desktop.in $(pixmap_DATA)

install-data-local:
	-$(mkinstalldirs) $(DESTDIR)$(scoredir)
	-chgrp games $(DESTDIR)$(bindir)/gnotski && chmod 2111 $(DESTDIR)$(bindir)/gnotski
	-touch             $(scoredir)/gnotski.1.scores
	-chown games.games $(scoredir)/gnotski.1.scores
	-chmod 664         $(scoredir)/gnotski.1.scores
	-touch             $(scoredir)/gnotski.2.scores
	-chown games.games $(scoredir)/gnotski.2.scores
	-chmod 664         $(scoredir)/gnotski.2.scores
	-touch             $(scoredir)/gnotski.3.scores
	-chown games.games $(scoredir)/gnotski.3.scores
	-chmod 664         $(scoredir)/gnotski.3.scores
	-touch             $(scoredir)/gnotski.4.scores
	-chown games.games $(scoredir)/gnotski.4.scores
	-chmod 664         $(scoredir)/gnotski.4.scores
	-touch             $(scoredir)/gnotski.5.scores
	-chown games.games $(scoredir)/gnotski.5.scores
	-chmod 664         $(scoredir)/gnotski.5.scores
	-touch             $(scoredir)/gnotski.6.scores
	-chown games.games $(scoredir)/gnotski.6.scores
	-chmod 664         $(scoredir)/gnotski.6.scores
	-touch             $(scoredir)/gnotski.7.scores
	-chown games.games $(scoredir)/gnotski.7.scores
	-chmod 664         $(scoredir)/gnotski.7.scores
	-touch             $(scoredir)/gnotski.11.scores
	-chown games.games $(scoredir)/gnotski.11.scores
	-chmod 664         $(scoredir)/gnotski.11.scores
	-touch             $(scoredir)/gnotski.12.scores
	-chown games.games $(scoredir)/gnotski.12.scores
	-chmod 664         $(scoredir)/gnotski.12.scores
	-touch             $(scoredir)/gnotski.13.scores
	-chown games.games $(scoredir)/gnotski.13.scores
	-chmod 664         $(scoredir)/gnotski.13.scores
	-touch             $(scoredir)/gnotski.14.scores
	-chown games.games $(scoredir)/gnotski.14.scores
	-chmod 664         $(scoredir)/gnotski.14.scores
	-touch             $(scoredir)/gnotski.15.scores
	-chown games.games $(scoredir)/gnotski.15.scores
	-chmod 664         $(scoredir)/gnotski.15.scores
	-touch             $(scoredir)/gnotski.16.scores
	-chown games.games $(scoredir)/gnotski.16.scores
	-chmod 664         $(scoredir)/gnotski.16.scores
	-touch             $(scoredir)/gnotski.17.scores
	-chown games.games $(scoredir)/gnotski.17.scores
	-chmod 664         $(scoredir)/gnotski.17.scores
	-touch             $(scoredir)/gnotski.21.scores
	-chown games.games $(scoredir)/gnotski.21.scores
	-chmod 664         $(scoredir)/gnotski.21.scores
	-touch             $(scoredir)/gnotski.22.scores
	-chown games.games $(scoredir)/gnotski.22.scores
	-chmod 664         $(scoredir)/gnotski.22.scores
	-touch             $(scoredir)/gnotski.23.scores
	-chown games.games $(scoredir)/gnotski.23.scores
	-chmod 664         $(scoredir)/gnotski.23.scores
	-touch             $(scoredir)/gnotski.24.scores
	-chown games.games $(scoredir)/gnotski.24.scores
	-chmod 664         $(scoredir)/gnotski.24.scores
	-touch             $(scoredir)/gnotski.25.scores
	-chown games.games $(scoredir)/gnotski.25.scores
	-chmod 664         $(scoredir)/gnotski.25.scores
	-touch             $(scoredir)/gnotski.26.scores
	-chown games.games $(scoredir)/gnotski.26.scores
	-chmod 664         $(scoredir)/gnotski.26.scores
