#!/usr/bin/env lua

require('test.test_luaunit')
lu = require('luaunit')

lu.LuaUnit.verbosity = 2
os.exit( lu.LuaUnit.run() )
