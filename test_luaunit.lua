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
        local function f() end

        has_error = not pcall( error, "coucou" )
        assert( has_error == true )
        assertError( error, "coucou" )
        has_error = not pcall( assertError, error, "coucou" )
        assert( has_error == false )

        has_error = not pcall( f )
        assert( has_error == false )
        has_error = not pcall( assertError, f )
        assert( has_error == true )

        -- multiple arguments
        local function multif(a,b,c)
            if a == b and b == c then return end
            error("three arguments not equal")
        end

        assertError( multif, 1, 1, 3 )
        assertError( multif, 1, 3, 1 )
        assertError( multif, 3, 1, 1 )

        has_error = not pcall( assertError, multif, 1, 1, 1 )
        assert( has_error == true )
    end

    function TestLuaUnit:test_assertEquals()
        assertEquals( 1, 1 )
        has_error = not pcall( assertEquals, 1, 2 )
        assert( has_error == true )
    end

    function TestLuaUnit:Xtest_xpcall()
        local function f() error("[this is a normal error]") end
        local function g() f() end
        g()
    end

    function TestLuaUnit:test_prefixString()
        assertEquals( prefixString( '12 ', 'ab\ncd\nde'), '12 ab\n12 cd\n12 de' )
    end

    function TestLuaUnit:test_MethodsAreExecutedInRightOrder()
        assertEquals( #executedTests, 0 )
        LuaUnit:runTestClassByName( 'MyTestToto1' )
        assertEquals( #executedTests, 5 )
    end

--[[ Class to test that tests are run in the right order ]]

executedTests = {}

MyTestToto1 = {} --class
    function MyTestToto1:test1() table.insert( executedTests, "TestToto1:test1" ) end
    function MyTestToto1:testb() table.insert( executedTests, "TestToto1:testb" ) end
    function MyTestToto1:test3() table.insert( executedTests, "TestToto1:test3" ) end
    function MyTestToto1:testa() table.insert( executedTests, "TestToto1:testa" ) end
    function MyTestToto1:test2() table.insert( executedTests, "TestToto1:test2" ) end

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
LuaUnit:run() -- will execute all tests

