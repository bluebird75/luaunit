# Makefile to simply run tests on Linux

LUA ?= lua
LUAJIT ?= luajit
LUACHECK ?= /usr/lib/lua/luarocks/bin/luacheck

#DATE_FORMAT ?= "%F %T" # ISO 8601 date, 24-hour time
DATE_FORMAT ?= "%m/%d/%y %T"

run: checks
	$(LUA) -v run_unit_tests.lua
	$(LUA) run_functional_tests.lua -v
	$(LUAJIT) -v run_unit_tests.lua
	$(LUAJIT) run_functional_tests.lua -v

checks:
	$(LUACHECK) *.lua test/

update:
	@# update the reference files using a fixed date format
	LUAUNIT_DATEFMT=$(DATE_FORMAT) $(LUA) run_functional_tests.lua --update $(UPDATE)
