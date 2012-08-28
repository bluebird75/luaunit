--[[ 
Author: Philippe Fremy <phil@freehackers.org>
License: BSD License, see LICENSE.txt

]]--

-- This is a bit tricky since the test uses the features that it tests.

require('luaunit')

TestLuaUnit = {} --class

    function TestLuaUnit:tearDown()
        executedTests = {}
    end

    function TestLuaUnit:test_assertError()
        local function f( v ) 
            v = v + 1
        end
        local function f_with_error(v)
            v = v + 2
            error('coucou')
        end

        local x = 1

        -- f_with_error generates an error
        has_error = not pcall( f_with_error, x )
        assertEquals( has_error, true )

        -- f does not generate an error
        has_error = not pcall( f, x )
        assertEquals( has_error, false )

        -- assertError is happy with f_with_error
        assertError( f_with_error, x )

        -- assertError is unhappy with f
        has_error = not pcall( assertError, f, x )
        assertError( has_error, true )

        -- multiple arguments
        local function f_with_multi_arguments(a,b,c)
            if a == b and b == c then return end
            error("three arguments not equal")
        end

        assertError( f_with_multi_arguments, 1, 1, 3 )
        assertError( f_with_multi_arguments, 1, 3, 1 )
        assertError( f_with_multi_arguments, 3, 1, 1 )

        has_error = not pcall( assertError, f_with_multi_arguments, 1, 1, 1 )
        assertEquals( has_error, true )
    end

    function TestLuaUnit:test_assertEquals()
        assertEquals( 1, 1 )
        assertError( assertEquals, 1, 2)
    end

    function TestLuaUnit:Xtest_xpcall()
        local function f() error("[this is a normal error]") end
        local function g() f() end
        g()
    end

    function TestLuaUnit:test_prefixString()
        assertEquals( prefixString( '12 ', 'ab\ncd\nde'), '12 ab\n12 cd\n12 de' )
    end

    executedTests = {}

    MyTestToto1 = {} --class
        function MyTestToto1:test1() table.insert( executedTests, "MyTestToto1:test1" ) end
        function MyTestToto1:testb() table.insert( executedTests, "MyTestToto1:testb" ) end
        function MyTestToto1:test3() table.insert( executedTests, "MyTestToto1:test3" ) end
        function MyTestToto1:testa() table.insert( executedTests, "MyTestToto1:testa" ) end
        function MyTestToto1:test2() table.insert( executedTests, "MyTestToto1:test2" ) end

    function TestLuaUnit:test_MethodsAreExecutedInRightOrder()
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuite( 'MyTestToto1' )
        assertEquals( #executedTests, 5 )
        assertEquals( executedTests[1], "MyTestToto1:test1" )
        assertEquals( executedTests[2], "MyTestToto1:test2" )
        assertEquals( executedTests[3], "MyTestToto1:test3" )
        assertEquals( executedTests[4], "MyTestToto1:testa" )
        assertEquals( executedTests[5], "MyTestToto1:testb" )
    end

    function TestLuaUnit:testRunTestClassByName( )
        assertEquals( #executedTests, 0 )
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runTestClass( 'MyTestToto1' )
        assertEquals( #executedTests, 5 )
    end

    function TestLuaUnit:testRunTestClassByGlobalInstance( )
        assertEquals( #executedTests, 0 )
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runTestClass( 'Toto', MyTestToto1 )
        assertEquals( #executedTests, 5 )
    end

    function TestLuaUnit:testRunTestClassByGlobalInstanceWithoutName( )
        assertEquals( #executedTests, 0 )
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runTestClass( nil, MyTestToto1 )
        assertEquals( #executedTests, 5 )
    end

    function TestLuaUnit:testRunTestClassByLocalInstance( )
        MyLocalTestToto1 = {} --class
        function MyLocalTestToto1:test1() table.insert( executedTests, "MyLocalTestToto1:test1" ) end
 
        assertEquals( #executedTests, 0 )
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runTestClass( 'MyLocalTestToto1', MyLocalTestToto1 )
        assertEquals( #executedTests, 1 )
        assertEquals( executedTests[1], 'MyLocalTestToto1:test1')
    end

    function TestLuaUnit:test_orderedNextReturnsOrderedKeyValues()
        t1 = {}
        t1['aaa'] = 'abc'
        t1['ccc'] = 'def'
        t1['bbb'] = 'cba'

        k, v = orderedNext( t1, nil )
        assertEquals( k, 'aaa' )
        assertEquals( v, 'abc' )
        k, v = orderedNext( t1, k )
        assertEquals( k, 'bbb' )
        assertEquals( v, 'cba' )
        k, v = orderedNext( t1, k )
        assertEquals( k, 'ccc' )
        assertEquals( v, 'def' )
        k, v = orderedNext( t1, k )
        assertEquals( k, nil )
        assertEquals( v, nil )
    end

    function TestLuaUnit:test_orderedNextWorksTwiceOnTable()
        t1 = {}
        t1['aaa'] = 'abc'
        t1['ccc'] = 'def'
        t1['bbb'] = 'cba'

        k, v = orderedNext( t1, nil )
        k, v = orderedNext( t1, k )
        k, v = orderedNext( t1, nil )
        assertEquals( k, 'aaa' )
        assertEquals( v, 'abc' )
    end

    function TestLuaUnit:test_orderedNextWorksOnTwoTables()
        t1 = { aaa = 'abc', ccc = 'def' }
        t2 = { ['3'] = '33', ['1'] = '11' }

        k, v = orderedNext( t1, nil )
        assertEquals( k, 'aaa' )
        assertEquals( v, 'abc' )

        k, v = orderedNext( t2, nil )
        assertEquals( k, '1' )
        assertEquals( v, '11' )

        k, v = orderedNext( t1, 'aaa' )
        assertEquals( k, 'ccc' )
        assertEquals( v, 'def' )

        k, v = orderedNext( t2, '1' )
        assertEquals( k, '3' )
        assertEquals( v, '33' )
    end

--[[ Class to test that tests are run in the right order ]]

--[[
TestToto2 = {} --class
    function TestToto2:test1() table.insert( executedTests, "TestToto2:test1" ) end
    function TestToto2:test2() table.insert( executedTests, "TestToto2:test2" ) end
    function TestToto2:test3() table.insert( executedTests, "TestToto2:test3" ) end
    function TestToto2:test4() table.insert( executedTests, "TestToto2:test4" ) end
    function TestToto2:test5() table.insert( executedTests, "TestToto2:test5" ) end
    function TestToto2:testa() table.insert( executedTests, "TestToto2:testa" ) end
    function TestToto2:testb() table.insert( executedTests, "TestToto2:testb" ) end


TestToto3 = {} --class
    function TestToto3:test1() table.insert( executedTests, "TestToto3:test1" ) end
    function TestToto3:test2() table.insert( executedTests, "TestToto3:test2" ) end
    function TestToto3:test3() table.insert( executedTests, "TestToto3:test3" ) end
    function TestToto3:test4() table.insert( executedTests, "TestToto3:test4" ) end
    function TestToto3:test5() table.insert( executedTests, "TestToto3:test5" ) end
    function TestToto3:testa() table.insert( executedTests, "TestToto3:testa" ) end
    function TestToto3:testb() table.insert( executedTests, "TestToto3:testb" ) end

TestTotoa = {} --class
    function TestTotoa:test1() table.insert( executedTests, "TestTotoa:test1" ) end
    function TestTotoa:test2() table.insert( executedTests, "TestTotoa:test2" ) end
    function TestTotoa:test3() table.insert( executedTests, "TestTotoa:test3" ) end
    function TestTotoa:test4() table.insert( executedTests, "TestTotoa:test4" ) end
    function TestTotoa:test5() table.insert( executedTests, "TestTotoa:test5" ) end
    function TestTotoa:testa() table.insert( executedTests, "TestTotoa:testa" ) end
    function TestTotoa:testb() table.insert( executedTests, "TestTotoa:testb" ) end

TestTotob = {} --class
    function TestTotob:test1() table.insert( executedTests, "TestTotob:test1" ) end
    function TestTotob:test2() table.insert( executedTests, "TestTotob:test2" ) end
    function TestTotob:test3() table.insert( executedTests, "TestTotob:test3" ) end
    function TestTotob:test4() table.insert( executedTests, "TestTotob:test4" ) end
    function TestTotob:test5() table.insert( executedTests, "TestTotob:test5" ) end
    function TestTotob:testa() table.insert( executedTests, "TestTotob:testa" ) end
    function TestTotob:testb() table.insert( executedTests, "TestTotob:testb" ) end
]]

-- LuaUnit:run('TestLuaBinding:test_setline') -- will execute only one test
-- LuaUnit:run('TestLuaBinding') -- will execute only one class of test
-- LuaUnit.result.verbosity = 0

function dispParams(isReturn)
    local params = ''
    local level = 3
    local firstParam=true
    local sep=''
    local idx=1
    if isReturn then
        level = 4
    end
    local var, val = debug.getlocal(level,idx)
    while var ~= nil do
        if var ~= '(*temporary)' then
            params = params..sep..var..'='..tostring(val)
            if firstParam then
                sep = ', '
                firstParam = false
            end
        end
        idx = idx + 1
        var,val = debug.getlocal(level,idx)
    end
    if string.len(params) then
        if isReturn then
            return '()\n'..params
        end
        return '('..params..' )'
    end
    return nil
end

function debug_print( event )
    local extra = ''
    local info = debug.getinfo(2, 'n')
    level = level or 0
    if event == 'call' then
        level = level + 1
    end
    indentPrefix = string.rep( '  ', level )
    if info.namewhat == 'global' or info.namewhat == 'method' then
        local name = info.namewhat
        if info.name and name ~= info.name then
            name = name..' '..info.name
        end
        if event == 'call' or event == 'return' then
            local extra = dispParams(event == 'return')
            if extra then
                name = name..extra
            end
        end
        print( "DEBUG: "..indentPrefix..event..' '..name )
    end
    if event == 'return' then
        level = level - 1
    end
end

-- debug.sethook( debug_print, 'cr' )
LuaUnit:run() -- will execute all tests

--[[ More tests ]]
-- check return value of Run()
-- check failure count and test count
-- check that output are called with correct values
-- check that assertions produce real errors
-- strip luaunit stack more intelligently
-- table assertions
-- better verbosity support
-- assert contains
-- more user documentation
-- compatibilty tests with several version of lua
-- allow for errors in teardown and setup
-- real test for wrapFunctions
-- find more intelligent way than loadstring( fname.."()") to call test methods
