#!/usr/bin/env lua

require('test.test_luaunit')
local lu = require('luaunit')

lu.LuaUnit.verbosity = 2
os.exit( lu.LuaUnit.run() )
