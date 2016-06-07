#!/usr/bin/env lua
local checks = require("test.static_checks")

local strict = arg[1] == "--strict" -- will also check for global GETs

-- ANSI terminal escape codes for colored output
local ANSI_RED   = "\27[31;1m"
local ANSI_GREEN = "\27[32;1m"
local ANSI_RESET = "\27[0m"

--[[
A table of filenames to test, and exceptions (variable name patterns) they need.
If "allowed" is absent (= nil), then the file requires no special treatment.
]]
local files_and_exceptions = {
    { "luaunit.lua",
      allowed = {"LuaUnit", "EXPORT_ASSERT_TO_GLOBALS"}},
    { "example_with_luaunit.lua",
      allowed = {"LuaUnit", "EXPORT_ASSERT_TO_GLOBALS", "[Tt]est[%w_]+",
                 "assertEquals", "assertNotEquals", "assertTrue", "assertFalse"}},

    { "run_unit_tests.lua" },
    { "run_functional_tests.lua", allowed = {"test%w+"}},
    { "run_static_tests.lua" },

    { "test/compat_luaunit_v2x.lua",
      allowed = {"EXPORT_ASSERT_TO_GLOBALS", "[Tt]est[%w_]+", "assert%w+"}},
    { "test/legacy_example_with_luaunit.lua",
      allowed = {"LuaUnit", "EXPORT_ASSERT_TO_GLOBALS", "[Tt]est[%w_]+",
                 "assertEquals", "assertNotEquals", "assertTrue", "assertFalse"}},
    { "test/static_checks.lua" },
    { "test/test_luaunit.lua",
      allowed = {"TestMock", "TestLuaUnit%a+", "MyTest%w+"}},
    { "test/test_with_err_fail_pass.lua", allowed = {"[Tt]est[%w_]+"}},
    { "test/test_with_xml.lua", allowed = {"Test%w+"}},
}

local problems = 0
for _, test in ipairs(files_and_exceptions) do
    problems = problems + checks.check_globals(test[1], test.allowed, strict)
    --if problems > 0 then break; end
end

if problems == 0 then
    print(ANSI_GREEN .. "No problems detected." .. ANSI_RESET)
    os.exit(0)
end
print(ANSI_RED .. problems .. " (potential) problems detected!" .. ANSI_RESET)
os.exit(1)
