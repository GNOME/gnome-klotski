SUBDIRS = icons

gsettings_in_file = org.gnome.klotski.gschema.xml.in
gsettings_SCHEMAS = $(gsettings_in_file:.xml.in=.xml)
@INTLTOOL_XML_NOMERGE_RULE@
@GSETTINGS_RULES@

man_MANS = gnome-klotski.6

pixmapdir = $(datadir)/gnome-klotski
pixmap_DATA = \
	gnome-klotski.svg

desktopdir = $(datadir)/applications
desktop_in_files = gnome-klotski.desktop.in.in
desktop_DATA = $(desktop_in_files:.desktop.in.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

EXTRA_DIST = \
	$(gsettings_in_file)	\
	$(desktop_in_files)	\
	$(man_MANS)		\
	$(pixmap_DATA)

CLEANFILES = $(desktop_DATA) $(gsettings_SCHEMAS)
DISTCLEANFILES = $(desktop_DATA) $(gsettings_SCHEMAS)

-include $(top_srcdir)/git.mk
