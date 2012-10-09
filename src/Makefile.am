bin_PROGRAMS = gnome-klotski

gnome_klotski_SOURCES = \
	gnome-klotski.c	\
	games-fullscreen-action.c	\
	games-fullscreen-action.h	\
	games-gridframe.c	\
	games-gridframe.h	\
	games-preimage.c	\
	games-preimage.h	\
	games-score.h			\
	games-score.c			\
	games-scores.c			\
	games-scores.h			\
	games-scores-dialog.c	\
	games-scores-dialog.h	\
	games-scores-backend.c	\
	games-scores-backend.h	\
	games-stock.c	\
	games-stock.h	\
	pieces.h

if ENABLE_SETGID
gnome_klotski_SOURCES +=		\
	games-setgid-io.c		\
	games-setgid-io.h
endif # ENABLE_SETGID

gnome_klotski_CPPFLAGS = \
	-I$(top_srcdir) \
	$(AM_CPPFLAGS)

gnome_klotski_CFLAGS = \
	-DDATA_DIRECTORY=\"$(datadir)/gnome-klotski\" \
	-DLOCALEDIR=\"$(datadir)/locale\" \
	-DICON_THEME_DIRECTORY="\"$(datadir)/icons\"" \
	-DSCORESDIR="\"$(scoredir)\""				\
	$(GNOME_KLOTSKI_CFLAGS)

gnome_klotski_LDADD = \
	$(GNOME_KLOTSKI_LIBS)

install-exec-hook:
	-if test "$(setgid)" = "true"; then \
	  chgrp $(scores_group) $(DESTDIR)$(bindir)/gnome-klotski && chmod 2555 $(DESTDIR)$(bindir)/gnome-klotski ;\
	fi

-include $(top_srcdir)/git.mk
