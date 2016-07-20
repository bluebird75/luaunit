package = "LuaUnit"
version = "3.2.1-1"
source =
{
	url = "git://github.com/bluebird75/luaunit",
	
	tag = "LUAUNIT_V3_2_1"
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

		LuaUnit works with Lua 5.1, LuaJIT 2.0, LuaJIT 2.1 beta, Lua 5.2 and Lua 5.3 . It is tested on Windows Seven, Windows Server 2012 R2 (x64) and Ubuntu 14.04 (see continuous build results on Travis-CI and AppVeyor) and should work on all platforms supported by Lua.
		It has no other dependency than Lua itself. 

		**Important note when upgrading to version 3.1 and above** : break of backward compatibility, assertions functions are
		no longer exported directly to the global namespace. See [documentation](http://luaunit.readthedocs.io/en/latest/#luaunit-global-asserts) on how to adjust or restore previous behavior.

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
	-- copy_directories = { "doc/html" }
}
