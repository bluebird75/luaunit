EXPORT_ASSERT_TO_GLOBALS = true
local lu = require('luaunit')

--[[
Use Luaunit in the v2.1 fashion and check that it still works. 
Exercise every luaunit v2.1 function and have it executed successfully.

Coverage:
x Made LuaUnit:run() method able to be called with 'run' or 'Run'.
x Made LuaUnit.wrapFunctions() function able to be called with 'wrapFunctions' or 'WrapFunctions' or 'wrap_functions'.
x Moved wrapFunctions to the LuaUnit module table (e.g. local LuaUnit = require( "luaunit" ); LuaUnit.wrapFunctions( ... ) )
x Added LuaUnit.is<Type> and LuaUnit.is_<type> helper functions. (e.g. assert( LuaUnit.isString( getString() ) )
x Added assert<Type> and assert_<type> 
x Added assertNot<Type> and assert_not_<type>
x Added _VERSION variable to hold the LuaUnit version
x Added LuaUnit:setVerbosity(lvl) method to the LuaUnit. Alias: LuaUnit:SetVerbosity() and LuaUnit:set_verbosity().
x Added table deep compare
x check that wrapFunctions works
x Made "testable" classes able to start with 'test' or 'Test' for their name.
x Made "testable" methods able to start with 'test' or 'Test' for their name.
x Made testClass:setUp() methods able to be named with 'setUp' or 'Setup' or 'setup'.
x Made testClass:tearDown() methods able to be named with 'tearDown' or 'TearDown' or 'teardown'.
]]


TestLuaUnitV2Compat = {}

function TestLuaUnitV2Compat:testRunAliases()
    -- some old function
    assertFunction( lu.run )
    assertEquals( lu.Run, lu.run )
end

function TestLuaUnitV2Compat:testWrapFunctionsAliases()
    assertFunction( lu.wrapFunctions )
    assertEquals( lu.wrapFunctions, lu.WrapFunctions )
    assertEquals( lu.wrapFunctions, lu.wrap_functions )
end

local function typeAsserter( goodType, badType, goodAsserter, badAsserter )
    goodAsserter( goodType )
    if badAsserter ~= nil then
        badAsserter( badType )
    end
end

function TestLuaUnitV2Compat:testAssertType()
    local f = function (v) return v+1 end
    local t = coroutine.create( function(v) local y=v+1 end )
    local typesToVerify = {
        -- list of: { goodType, badType, goodAsserter, badAsserter }
        {  true, "toto", assertBoolean,  assertNotBoolean },
        {  true, "toto", assert_boolean, assert_not_boolean },
        {  1   , "toto", assertNumber,   assertNotNumber },
        {  1   , "toto", assert_number,  assert_not_number },
        {  "q" , 1     , assertString,   assertNotString },
        {  "q" , 1     , assert_string,  assert_not_string },
        {  nil , 1     , assertNil,      assertNotNil },
        {  nil , 1     , assert_nil,     assert_not_nil },
        { {1,2}, "toto", assertTable,    assertNotTable },
        { {1,2}, "toto", assert_table,   assert_not_table },
        { f    , "toto", assertFunction, assertNotFunction },
        { f    , "toto", assert_function,assert_not_function },
        { t    , "toto", assertThread,   assertNotThread },
        { t    , "toto", assert_thread,  assert_not_thread },

    }

    for _,v in ipairs( typesToVerify ) do 
        local goodType, badType, goodAsserter, badAsserter = v[1], v[2], v[3], v[4]
        typeAsserter( goodType, badType, goodAsserter, badAsserter )
    end

    assertNotUserdata( "toto" )


    local typesToVerify2 = {
        { true, "toto", lu.isBoolean },
        { true, "toto", lu.is_boolean },
        { 1,    "toto", lu.isNumber },
        { 1,    "toto", lu.is_number },
        { "t",       1, lu.isString },
        { "t",       1, lu.is_string },
        { nil,  "toto", lu.isNil },
        { nil,  "toto", lu.is_nil },
        { {1,2},"toto", lu.isTable },
        { {1,2},"toto", lu.is_table },
        { f,    "toto", lu.isFunction },
        { f,    "toto", lu.is_function },
        { t,    "toto", lu.isThread },
        { t,    "toto", lu.is_thread },
    }

    for _,v in ipairs( typesToVerify2 ) do 
        local goodType, badType, goodTypeVerifier = v[1], v[2], v[3]
        if (v[3] == nil) then
            print('Missing function at index '.._)
            assertNotNil( v[3] )
        end
        assertTrue ( goodTypeVerifier( goodType ) )
        assertFalse( goodTypeVerifier( badType ) )
    end

end

function TestLuaUnitV2Compat:testHasVersionKey()
    assertNotNil( lu.VERSION )
    assertString( lu.VERSION )
    assertNotNil( lu._VERSION )
    assertTrue( lu.is_string( lu._VERSION ) )
end

function TestLuaUnitV2Compat:testTableEquality()
    local t1 = {1,2}
    local t2 = t1
    local t3 = {1,2}
    local t4 = {1,2,3}

    assertEquals( t1, t1 )
    assertEquals( t1, t2 )
    -- new in LuaUnit v2.0 , deep table compare
    assertEquals( t1, t3 )
    assertError( assertEquals, t1, t4 )
end

-- Setup
local called = {}

function test_w1() called.w1 = true end
function test_w2() called.w2 = true end
function test_w3() called.w3 = true end

TestSomeFuncs = lu.wrapFunctions( 'test_w1', 'test_w2', 'test_w3' )

TestWithCap = {}
function TestWithCap:setup() called.setup = true end
function TestWithCap:Test1() called.t1 = true end
function TestWithCap:test2() called.t2 = true end
function TestWithCap:teardown() called.teardown = true end

testWithoutCap = {}
function testWithoutCap:Setup() called.Setup = true end
function testWithoutCap:Test3() called.t3 = true end
function testWithoutCap:test4() called.t4 = true end
function testWithoutCap:tearDown() called.tearDown = true end

TestWithUnderscore = {}
function TestWithUnderscore:setUp() called.setUp = true end
function TestWithUnderscore:Test1() called.t1 = true end
function TestWithUnderscore:test2() called.t2 = true end
function TestWithUnderscore:TearDown() called.TearDown = true end

-- Run
lu:setVerbosity( 1 )
lu:set_verbosity( 1 )
lu:SetVerbosity( 1 )

local results = lu.run()

-- Verif
assert( called.w1 == true )
assert( called.w2 == true )
assert( called.w3 == true )
assert( called.t1 == true )
assert( called.t2 == true )
assert( called.t3 == true )
assert( called.t4 == true )
assert( called.setup == true )
assert( called.setUp == true )
assert( called.Setup == true )
assert( called.teardown == true )
assert( called.tearDown == true )
assert( called.TearDown == true )

os.exit( results )
