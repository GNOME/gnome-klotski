bin_PROGRAMS = gnome-klotski

gnome_klotski_SOURCES = \
	config.vapi \
	gnome-klotski.vala \
	history.vala \
	puzzle.vala \
	puzzle-view.vala \
	score-dialog.vala

gnome_klotski_CFLAGS = \
	-DVERSION=\"$(VERSION)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
	-DDATA_DIRECTORY=\"$(datadir)/gnome-klotski\" \
	-DLOCALEDIR=\"$(datadir)/locale\" \
	-w \
	$(GNOME_KLOTSKI_CFLAGS)

gnome_klotski_VALAFLAGS = \
	--pkg posix \
	--pkg gtk+-3.0 \
	--pkg librsvg-2.0

gnome_klotski_LDADD = \
	$(GNOME_KLOTSKI_LIBS)

CLEANFILES = \
	$(patsubst %.vala,%.c,$(filter %.vala, $(SOURCES))) \
	*_vala.stamp

DISTCLEANFILES = \
	Makefile.in

-include $(top_srcdir)/git.mk
