pixmapdir = $(pkgdatadir)/gnotski/pixmaps
pixmap_DATA = \
	gnotski.svg	\
	$(NULL)

schema_in_files = gnotski.schemas.in
if HAVE_GNOME
schemadir = $(GCONF_SCHEMA_FILE_DIR)
schema_DATA = $(schema_in_files:.schemas.in=.schemas)
endif

man_MANS = gnotski.6

desktop_in_files = gnotski.desktop.in.in
desktopdir = $(datadir)/applications
desktop_DATA = $(desktop_in_files:.desktop.in.in=.desktop)

SCOREFILES = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37

EXTRA_DIST = \
	$(pixmap_DATA)		\
	$(schema_in_files)	\
	$(man_MANS)

CLEANFILES = $(desktop_DATA) $(schema_DATA)
DISTCLEANFILES = $(desktop_DATA) $(schema_DATA)

install-schemas-local: $(schema_DATA)
if GCONF_SCHEMAS_INSTALL
	if test -z "$(DESTDIR)" ; then \
		for p in $^ ; do \
			GCONF_CONFIG_SOURCE=$(GCONF_SCHEMA_CONFIG_SOURCE) $(GCONFTOOL) --makefile-install-rule $$p 2>&1 > /dev/null; \
		done \
	fi
endif

install-data-local: install-schemas-local

@INTLTOOL_SCHEMAS_RULE@
@INTLTOOL_DESKTOP_RULE@

-include $(top_srcdir)/git.mk
