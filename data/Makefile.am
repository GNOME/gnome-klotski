SUBDIRS = icons

gsettings_SCHEMAS = org.gnome.klotski.gschema.xml
@GSETTINGS_RULES@

man_MANS = gnome-klotski.6

pixmapdir = $(datadir)/gnome-klotski
pixmap_DATA = \
	gnome-klotski.svg

desktopdir = $(datadir)/applications
desktop_in_files = gnotski.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

appdatadir = $(datadir)/appdata
appdata_DATA = gnome-klotski.appdata.xml

EXTRA_DIST = \
	$(appdata_DATA)		\
	$(gsettings_SCHEMAS)	\
	$(desktop_in_files)	\
	$(man_MANS)		\
	$(pixmap_DATA)

CLEANFILES = $(desktop_DATA)

check-local: $(appdata_DATA) $(desktop_DATA)
	$(APPDATA_VALIDATE) $(appdata_DATA)
	$(DESKTOP_FILE_VALIDATE) $(desktop_DATA)

-include $(top_srcdir)/git.mk
