SHELL = /bin/sh

LUAVER=5.2
INSTALL = /usr/bin/install -c
DEST = /usr/local/share/lua/$(LUAVER)/

all: luaunit.lua

install: all
	$(INSTALL) luaunit.lua $(DEST)
