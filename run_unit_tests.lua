
require('test.test_luaunit')
LuaUnit = require('luaunit')

LuaUnit.LuaUnit.verbosity = 2
os.exit( LuaUnit.LuaUnit.run() )
