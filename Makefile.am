SUBDIRS = src data

if BUILD_HELP
SUBDIRS += help
endif

SCOREFILES = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37

install-data-local:
	-$(mkinstalldirs) $(DESTDIR)$(scoredir)
	-for i in ${SCOREFILES} ; do \
	  touch             $(DESTDIR)$(scoredir)/gnotski.$$i.scores; \
	  chown $(scores_user):$(scores_group) $(DESTDIR)$(scoredir)/gnotski.$$i.scores; \
	  chmod 664         $(DESTDIR)$(scoredir)/gnotski.$$i.scores; \
	done

-include $(top_srcdir)/git.mk
