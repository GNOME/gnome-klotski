SUBDIRS = icons

gsettings_SCHEMAS = org.gnome.klotski.gschema.xml
@GSETTINGS_RULES@

man_MANS = gnome-klotski.6

dist_noinst_DATA = \
	klotski.ui \
	klotski.css

pixmapdir = $(datadir)/gnome-klotski
pixmap_DATA = \
	gnome-klotski.svg

desktopdir = $(datadir)/applications
desktop_in_files = gnome-klotski.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
$(desktop_DATA): $(desktop_in_files)
	$(AM_V_GEN)$(MSGFMT) --desktop --template $< -d $(top_srcdir)/po -o $@

appstream_in_files = gnome-klotski.appdata.xml.in
appstream_XML = $(appstream_in_files:.xml.in=.xml)

$(appstream_XML): $(appstream_in_files)
	$(AM_V_GEN)$(MSGFMT) --xml --template $< -d $(top_srcdir)/po -o $@

@APPSTREAM_XML_RULES@

EXTRA_DIST = \
	$(appstream_in_files)	\
	$(gsettings_SCHEMAS)	\
	$(desktop_in_files)	\
	$(man_MANS)		\
	$(pixmap_DATA)

CLEANFILES = \
	$(appstream_XML)	\
	$(desktop_DATA)

check-local: $(desktop_DATA)
	$(DESKTOP_FILE_VALIDATE) $(desktop_DATA)

AM_DISTCHECK_CONFIGURE_FLAGS = --enable-appdata-check

-include $(top_srcdir)/git.mk
