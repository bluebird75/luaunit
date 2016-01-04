# Makefile to simply run tests on Linux

LUA ?= lua
LUAJIT ?= luajit
LUACHECK ?= /usr/lib/lua/luarocks/bin/luacheck

#DATE_FORMAT ?= "%F %T" # ISO 8601 date, 24-hour time
DATE_FORMAT ?= "%m/%d/%y %T"

STATS  = luacov.stats.out
REPORT = luacov.report.out

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

lua-coverage:
	@echo -e '\nLua coverage:'
	@echo -e '-------------\n'
	rm -f $(STATS)
	$(LUA) -v -lluacov run_unit_tests.lua
	$(LUA) run_functional_tests.lua --coverage -v
	luacov %./luaunit.lua
	grep -n '^\**0' $(REPORT) | grep -v ':\**0\W*error(' || true
	tail -n8 $(REPORT)

luajit-coverage:
	@echo -e '\nLuaJIT coverage:'
	@echo -e '----------------\n'
	rm -f $(STATS)
	$(LUAJIT) -v -lluacov run_unit_tests.lua
	$(LUAJIT) run_functional_tests.lua --coverage -v
	luacov %./luaunit.lua
	grep -n '^\**0' $(REPORT) | grep -v ':\**0\W*error(' || true
	tail -n8 $(REPORT)

# Unfortunately, the metrics differ between Lua and LuaJIT :/
# Let's do LuaJIT first, and preserve the Lua report that way.
coverage: luajit-coverage lua-coverage
