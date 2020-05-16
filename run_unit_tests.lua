#!/usr/bin/env lua
if (os.getenv("_DEBUG")) then
    local json = require 'json'
    local debuggee = require 'vscode-debuggee'

    local startResult, breakerType = debuggee.start(json)
    print('debuggee start ->', startResult, breakerType)
end


local no_error, err_msg
no_error, err_msg = pcall( require, 'test.test_luaunit')
if not no_error then
	if nil == err_msg:find( "module 'test.test_luaunit' not found" ) then
		-- module found but error loading it
		-- display the error by reproducing it
		require('test.test_luaunit')
	end

	-- run_unit_tests shall also work when called directly from the test directory
	require('test_luaunit')

	-- we must disable this test, not working in this case because it expects 
	-- the stack trace to start with test/test_luaunit.lua
	TestLuaUnitUtilities.test_FailFmt = nil
end
local lu = require('luaunit')

lu.LuaUnit.verbosity = 2
os.exit( lu.LuaUnit.run() )
