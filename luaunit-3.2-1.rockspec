package = "LuaUnit"
version = "3.2-1"
source =
{
	url = "git://github.com/bluebird75/luaunit",
	
	-- to be updated when v3.2 is released:
	-- tag = "LUAUNIT_V3_2"
}

description =
{
	summary = "A unit testing framework for Lua",
	detailed =
	[[
		Luaunit is a unit-testing framework for Lua. It allows you to write test functions and test classes with 
		test methods, combined with setup/teardown functionality. A wide range of assertions are supported.

		Luaunit supports several output format, like Junit or TAP, for easier integration into Continuous Integration 
		platforms (Jenkins, Maven, ...) . The integrated command-line options provide a flexible interface to select tests by name 
		or patterns, control output format, set verbosity, ...

		LuaUnit works with Lua 5.1, 5.2 and 5.3 . It was tested on Windows XP, Windows Server 2012 R2 (x64) and 
		Ubuntu 14.04 (see continuous build results on Travis-CI and AppVeyor ) and should work on all platforms 
		supported by lua. It has no other dependency than lua itself. 

	]],
	homepage = "http://github.com/bluebird75/luaunit",
	license = "BSD"
}

dependencies =
{
	"lua >= 5.1"
}

build =
{
	type = "builtin",
	modules =
	{
		luaunit = "luaunit.lua"
	},
	copy_directories = { "doc/html" }
}
