PREFIX = /usr/local
DEST = $(PREFIX)/bin
STOWDIR = $(PREFIX)/stow
STOWDEST = $(STOWDIR)/viewbug/bin
STOW = xstow
SOURCE = viewbug.sh

install: $(SOURCE)
	install -m 0755 $(SOURCE) $(DEST)

install-stow: $(SOURCE)
	install -m 0755 -d $(STOWDEST)
	install -m 0755 $(SOURCE) $(STOWDEST)
	cd $(STOWDIR)
	$(STOW) $(SOURCE:%.sh=%)
