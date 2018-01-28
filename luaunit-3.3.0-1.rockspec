package = "LuaUnit"
version = "3.3.0-1"
source =
{
	-- url = 'https://github.com/bluebird75/luaunit/releases/download/LUAUNIT_V3_3/luaunit-3.3.zip'
	url = 'release/luaunit-3.3.zip'
}

description =
{
	summary = "A unit testing framework for Lua",
	detailed =
	[[
		LuaUnit is a popular unit-testing framework for Lua, with an interface typical
		of xUnit libraries (Python unittest, Junit, NUnit, ...). It supports 
		several output formats (Text, TAP, JUnit, ...) to be used directly or work with Continuous Integration platforms
		(Jenkins, Maven, ...).

		For simplicity, LuaUnit is contained into a single-file and has no external dependency. 

		Tutorial and reference documentation is available on
		[read-the-docs](http://luaunit.readthedocs.org/en/latest/)

		LuaUnit may also be used as an assertion library, to validate assertions inside a running program. In addition, it provides
		a pretty stringifier, to convert any type into a nicely formatted string (including complex nested or recursive tables).

	]],
	homepage = "http://github.com/bluebird75/luaunit",
	license = "BSD",
	-- issues_url = "github ...",
	-- maintainer = 'bob...'
	-- labels = '...' see luarocks labels
}

dependencies =
{
	"lua >= 5.1", "lua < 5.4"
}

build =
{
	type = "builtin",
	modules =
	{
		luaunit = "luaunit.lua"
	},
	copy_directories = { "doc", "test" }
}
