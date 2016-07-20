--[[
Luacheck configuration
(see http://luacheck.readthedocs.io/en/stable/config.html)
Thanks to Peter Melnichenko for providing an example file for LuaUnit.
]]

only = {"1"} -- limit checks to the use of global variables
std = "max"

files = {
    ["luaunit.lua"] = {
        ignore = {"LuaUnit", "EXPORT_ASSERT_TO_GLOBALS"}
    },
    ["example_with_luaunit.lua"] = {
        ignore = {"LuaUnit", "EXPORT_ASSERT_TO_GLOBALS", "[Tt]est[%w_]+",
        "assertEquals", "assertNotEquals", "assertTrue", "assertFalse"}
    },
    ["run_functional_tests.lua"] = {
        ignore = {"test%w+"}
    },
    ["test/compat_luaunit_v2x.lua"] = {
        ignore = {"EXPORT_ASSERT_TO_GLOBALS", "[Tt]est[%w_]+", "assert[%w_]+"}
    },
    ["test/legacy_example_with_luaunit.lua"] = {
        ignore = {"LuaUnit", "EXPORT_ASSERT_TO_GLOBALS", "[Tt]est[%w_]+",
        "assertEquals", "assertNotEquals", "assertTrue", "assertFalse"}
    },
    ["test/test_luaunit.lua"] = {
        ignore = {"TestMock", "TestLuaUnit%a+", "MyTest%w+"}},
    ["test/test_with_err_fail_pass.lua"] = {
        ignore = {"[Tt]est[%w_]+"}
    },
    ["test/test_with_xml.lua"] = {
        ignore = {"Test%w+"}
    }
}
