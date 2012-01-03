SUBDIRS = icons

pixmapdir = $(datadir)/gnotski
pixmap_DATA = \
	gnotski.svg

gsettings_in_file = org.gnome.gnotski.gschema.xml.in
gsettings_SCHEMAS = $(gsettings_in_file:.xml.in=.xml)
@INTLTOOL_XML_NOMERGE_RULE@
@GSETTINGS_RULES@

man_MANS = gnotski.6

desktop_in_files = gnotski.desktop.in.in
desktopdir = $(datadir)/applications
desktop_DATA = $(desktop_in_files:.desktop.in.in=.desktop)

SCOREFILES = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37

EXTRA_DIST = \
	$(pixmap_DATA)		\
	$(gsettings_in_file)	\
	$(man_MANS) \
	$(desktop_in_files)

CLEANFILES = $(desktop_DATA) $(gsettings_SCHEMAS)
DISTCLEANFILES = $(desktop_DATA) $(gsettings_SCHEMAS)

@INTLTOOL_DESKTOP_RULE@

-include $(top_srcdir)/git.mk
