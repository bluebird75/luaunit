--[[ 
Author: Philippe Fremy <phil@freehackers.org>
License: BSD License, see LICENSE.txt

]]--

-- This is a bit tricky since the test uses the features that it tests.

require('luaunit')

Mock = {
    __class__ = 'Mock',
    calls = {}    
}

function Mock:new()
    local t = {}
    t.__class__ = 'Mock'
    t.calls = {}

    function t.callRecorder( callInfo )
        -- Return a function that stores its arguments in callInfo
        function f( ... )
            -- Not lua 5.0 compliant:
            args ={...}
            for i,v in pairs(args) do
                table.insert( callInfo, v )
            end
        end
        return f
    end

    local t_MT = {}
    function t_MT.__index( t, key ) 
        local callInfo = { key }
        table.insert( t.calls, callInfo )
        return t.callRecorder( callInfo )
    end

    setmetatable( t, t_MT )
    return t 
end


TestMock = {}
    function TestMock:testMock()
        m = Mock:new()
        m.titi( 42 )
        m.toto( 33, "abc", { 21} )
        assertEquals(  m.calls[1][1], 'titi' )
        assertEquals(  m.calls[1][2], 42 )
        assertEquals( #m.calls[1], 2 )

        assertEquals(  m.calls[2][1], 'toto' )
        assertEquals(  m.calls[2][2], 33 )
        assertEquals(  m.calls[2][3], 'abc' )
        assertEquals(  m.calls[2][4][1], 21 )
        assertEquals( #m.calls[2], 4 )

        assertEquals( #m.calls, 2 )
    end

------------------------------------------------------------------
--
--                      Utility Tests              
--
------------------------------------------------------------------

TestLuaUnitUtilities = {} --class

    TestLuaUnitUtilities.__class__ = 'TestLuaUnitUtilities'


    function TestLuaUnitUtilities:test_genSortedIndex()
        assertEquals( __genSortedIndex( { 2, 5, 7} ), {1,2,3} )
        assertEquals( __genSortedIndex( { a='1', h='2', c='3' } ), {'a', 'c', 'h'} )
        assertEquals( __genSortedIndex( { 1, 'z', a='1', h='2', c='3' } ), { 1, 2, 'a', 'c', 'h' } )
    end

    function TestLuaUnitUtilities:test_sortedNextReturnsSortedKeyValues()
        t1 = {}
        t1['aaa'] = 'abc'
        t1['ccc'] = 'def'
        t1['bbb'] = 'cba'

        k, v = sortedNext( t1, nil )
        assertEquals( k, 'aaa' )
        assertEquals( v, 'abc' )
        k, v = sortedNext( t1, k )
        assertEquals( k, 'bbb' )
        assertEquals( v, 'cba' )
        k, v = sortedNext( t1, k )
        assertEquals( k, 'ccc' )
        assertEquals( v, 'def' )
        k, v = sortedNext( t1, k )
        assertEquals( k, nil )
        assertEquals( v, nil )
    end

    function TestLuaUnitUtilities:test_sortedNextWorksTwiceOnTable()
        t1 = {}
        t1['aaa'] = 'abc'
        t1['ccc'] = 'def'
        t1['bbb'] = 'cba'

        k, v = sortedNext( t1, nil )
        k, v = sortedNext( t1, k )
        k, v = sortedNext( t1, nil )
        assertEquals( k, 'aaa' )
        assertEquals( v, 'abc' )
    end

    function TestLuaUnitUtilities:test_sortedNextWorksOnTwoTables()
        t1 = { aaa = 'abc', ccc = 'def' }
        t2 = { ['3'] = '33', ['1'] = '11' }

        k, v = sortedNext( t1, nil )
        assertEquals( k, 'aaa' )
        assertEquals( v, 'abc' )

        k, v = sortedNext( t2, nil )
        assertEquals( k, '1' )
        assertEquals( v, '11' )

        k, v = sortedNext( t1, 'aaa' )
        assertEquals( k, 'ccc' )
        assertEquals( v, 'def' )

        k, v = sortedNext( t2, '1' )
        assertEquals( k, '3' )
        assertEquals( v, '33' )
    end

    function TestLuaUnitUtilities:test_strSplitOneCharDelim()
        t = strsplit( '\n', '1\n22\n333\n' )
        assertEquals( t[1], '1')
        assertEquals( t[2], '22')
        assertEquals( t[3], '333')
        assertEquals( t[4], '')
        assertEquals( #t, 4 )
    end

    function TestLuaUnitUtilities:test_strSplit3CharDelim()
        t = strsplit( '2\n3', '1\n22\n332\n3' )
        assertEquals( t[1], '1\n2')
        assertEquals( t[2], '3')
        assertEquals( t[3], '')
        assertEquals( #t, 3 )
    end

    function TestLuaUnitUtilities:test_strSplitOnFailure()
        s1 = 'd:/work/luaunit/luaunit-git/luaunit/test_luaunit.lua:467: expected: 1, actual: 2\n'
        s2 = [[stack traceback:
    .\luaunit.lua:443: in function <.\luaunit.lua:442>
    [C]: in function 'error'
    .\luaunit.lua:56: in function 'assertEquals'
    d:/work/luaunit/luaunit-git/luaunit/test_luaunit.lua:467: in function <d:/work/luaunit/luaunit-git/luaunit/test_luaunit.lua:466>
    [C]: in function 'xpcall'
    .\luaunit.lua:447: in function 'protectedCall'
    .\luaunit.lua:479: in function '_runTestMethod'
    .\luaunit.lua:527: in function 'runTestMethod'
    .\luaunit.lua:569: in function 'runTestClass'
    .\luaunit.lua:609: in function <.\luaunit.lua:588>
    (...tail calls...)
    d:/work/luaunit/luaunit-git/luaunit/test_luaunit.lua:528: in main chunk
    [C]: in ?
]]
        t = strsplit( SPLITTER, s1..SPLITTER..s2)
        assertEquals( t[1], s1)
        assertEquals( t[2], s2)
        assertEquals( #t, 2 )
    end

    function TestLuaUnitUtilities:test_prefixString()
        assertEquals( prefixString( '12 ', 'ab\ncd\nde'), '12 ab\n12 cd\n12 de' )
    end


    function TestLuaUnitUtilities:test_table_keytostring()
        assertEquals( table.keytostring( 'a' ), 'a' )
        assertEquals( table.keytostring( 'a0' ), 'a0' )
        assertEquals( table.keytostring( 'a0!' ), '"a0!"' )
    end

    function TestLuaUnitUtilities:test_mytostring()
        assertEquals( mytostring( 1 ), "1" )
        assertEquals( mytostring( 1.1 ), "1.1" )
        assertEquals( mytostring( 'abc' ), '"abc"' )
        assertEquals( mytostring( 'ab\ncd' ), '"ab\ncd"' )
        assertEquals( mytostring( 'ab\ncd', true ), '"ab\\ncd"' )
        assertEquals( mytostring( 'ab"cd' ), "'ab\"cd'" )
        assertEquals( mytostring( "ab'cd" ), '"ab\'cd"' )
        assertEquals( mytostring( {1,2,3} ), "{1,2,3}" )
        assertEquals( mytostring( {a=1,bb=2,ab=3} ), '{a=1,ab=3,bb=2}' )
    end



------------------------------------------------------------------
--
--                  Assertion Tests              
--
------------------------------------------------------------------

TestLuaUnitAssertions = {} --class

    TestLuaUnitAssertions.__class__ = 'TestLuaUnitAssertions'

    function TestLuaUnitAssertions:test_assertError()
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

    function TestLuaUnitAssertions:test_assertEquals()
        f = function() return true end
        g = function() return true end
        
        assertEquals( 1, 1 )
        assertEquals( "abc", "abc" )
        assertEquals( nil, nil )
        assertEquals( true, true )
        assertEquals( f, f)
        assertEquals( {1,2,3}, {1,2,3})
        assertEquals( {one=1,two=2,three=3}, {one=1,two=2,three=3})
        assertEquals( {one=1,two=2,three=3}, {two=2,three=3,one=1})
        assertEquals( {one=1,two={1,2},three=3}, {two={1,2},three=3,one=1})
        assertEquals( {one=1,two={1,{2,nil}},three=3}, {two={1,{2,nil}},three=3,one=1})
        assertEquals( {nil}, {nil} )

        assertError( assertEquals, 1, 2)
        assertError( assertEquals, 1, "abc" )
        assertError( assertEquals, 0, nil )
        assertError( assertEquals, false, nil )
        assertError( assertEquals, true, 1 )
        assertError( assertEquals, f, 1 )
        assertError( assertEquals, f, g )
        assertError( assertEquals, {1,2,3}, {2,1,3} )
        assertError( assertEquals, {1,2,3}, nil )
        assertError( assertEquals, {1,2,3}, 1 )
        assertError( assertEquals, {1,2,3}, true )
        assertError( assertEquals, {1,2,3}, {one=1,two=2,three=3} )
        assertError( assertEquals, {1,2,3}, {one=1,two=2,three=3,four=4} )
        assertError( assertEquals, {one=1,two=2,three=3}, {2,1,3} )
        assertError( assertEquals, {one=1,two=2,three=3}, nil )
        assertError( assertEquals, {one=1,two=2,three=3}, 1 )
        assertError( assertEquals, {one=1,two=2,three=3}, true )
        assertError( assertEquals, {one=1,two=2,three=3}, {1,2,3} )
        assertError( assertEquals, {one=1,two={1,2},three=3}, {two={2,1},three=3,one=1})
    end

    function TestLuaUnitAssertions:test_assertNotEquals()
        f = function() return true end
        g = function() return true end

        assertNotEquals( 1, 2 )
        assertNotEquals( "abc", 2 )
        assertNotEquals( "abc", "def" )
        assertNotEquals( 1, 2)
        assertNotEquals( 1, "abc" )
        assertNotEquals( 0, nil )
        assertNotEquals( false, nil )
        assertNotEquals( true, 1 )
        assertNotEquals( f, 1 )
        assertNotEquals( f, g )
        assertNotEquals( {one=1,two=2,three=3}, true )
        assertNotEquals( {one=1,two={1,2},three=3}, {two={2,1},three=3,one=1} )

        assertError( assertNotEquals, 1, 1)
        assertError( assertNotEquals, "abc", "abc" )
        assertError( assertNotEquals, nil, nil )
        assertError( assertNotEquals, true, true )
        assertError( assertNotEquals, f, f)
        assertError( assertNotEquals, {one=1,two={1,{2,nil}},three=3}, {two={1,{2,nil}},three=3,one=1})

    end

    function TestLuaUnitAssertions:test_assertNotEqualsDifferentTypes2()
        assertNotEquals( 2, "abc" )
    end

    function TestLuaUnitAssertions:test_assertTrue()
        assertTrue(true)
        assertError( assertTrue, false)
        assertTrue(0)
        assertTrue(1)
        assertTrue("")
        assertTrue("abc")
        assertError( assertTrue, nil )
        assertTrue( function() return true end )
        assertTrue( {} )
        assertTrue( { 1 } )
    end

    function TestLuaUnitAssertions:test_assertFalse()
        assertFalse(false)
        assertError( assertFalse, true)
        assertFalse( nil )
        assertError( assertFalse, 0 )
        assertError( assertFalse, 1 )
        assertError( assertFalse, "" )
        assertError( assertFalse, "abc" )
        assertError( assertFalse, function() return true end )
        assertError( assertFalse, {} )
        assertError( assertFalse, { 1 } )
    end

    function TestLuaUnitAssertions:test_assertStrContains()
        assertStrContains( 'abcdef', 'abc' )
        assertStrContains( 'abcdef', 'bcd' )
        assertStrContains( 'abcdef', 'abcdef' )
        assertStrContains( 'abc0', 0 )
        assertError( assertStrContains, 'ABCDEF', 'abc' )
        assertError( assertStrContains, '', 'abc' )
        assertStrContains( 'abcdef', '' )
        assertError( assertStrContains, 'abcdef', 'abcx' )
        assertError( assertStrContains, 'abcdef', 'abcdefg' )
        assertError( assertStrContains, 'abcdef', 0 ) 
        assertError( assertStrContains, 'abcdef', {} ) 
        assertError( assertStrContains, 'abcdef', nil ) 
    end

    function TestLuaUnitAssertions:test_assertStrIContains()
        assertStrIContains( 'ABcdEF', 'aBc' )
        assertStrIContains( 'abCDef', 'bcd' )
        assertStrIContains( 'abcdef', 'abcDef' )
        assertError( assertStrIContains, '', 'aBc' )
        assertStrIContains( 'abcDef', '' )
        assertError( assertStrIContains, 'abcdef', 'abcx' )
        assertError( assertStrIContains, 'abcdef', 'abcdefg' )
    end

    function TestLuaUnitAssertions:test_assertNotStrContains()
        assertError( assertNotStrContains, 'abcdef', 'abc' )
        assertError( assertNotStrContains, 'abcdef', 'bcd' )
        assertError( assertNotStrContains, 'abcdef', 'abcdef' )
        assertNotStrContains( '', 'abc' )
        assertError( assertNotStrContains, 'abcdef', '' )
        assertError( assertNotStrContains, 'abc0', 0 )
        assertNotStrContains( 'abcdef', 'abcx' )
        assertNotStrContains( 'abcdef', 'abcdefg' )
        assertError( assertNotStrContains, 'abcdef', {} ) 
        assertError( assertNotStrContains, 'abcdef', nil ) 
    end


    function TestLuaUnitAssertions:test_assertItemsEquals()
        assertItemsEquals(nil, nil)
        assertError(assertItemsEquals, {1}, {})
        assertError(assertItemsEquals, nil, {1,2,3})
        assertError(assertItemsEquals, {1,2,3}, nil)
        assertItemsEquals({1,2,3}, {3,1,2})
        assertItemsEquals({nil},{nil})
        assertItemsEquals({1,{2,1},3}, {3,1,{1,2}})
        assertItemsEquals({one=1,two=2,three=3}, {two=2,one=1,three=3})
        assertItemsEquals({one=1,two={1,2},three=3}, {two={2,1},one=1,three=3})
        assertItemsEquals({one=1,two={1,{3,2,one=1}},three=3}, {two={{3,one=1,2},1},one=1,three=3})
        assertError(assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1,three=2})
        assertError(assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1,four=4})
        assertError(assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1,three})
        assertError(assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1,nil})
        assertError(assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1})
    end

    function TestLuaUnitAssertions:test_assertIsNumber()
        assertIsNumber(1)
        assertIsNumber(1.4)
        assertError(assertIsNumber, "hi there!")
        assertError(assertIsNumber, nil)
        assertError(assertIsNumber, {})
        assertError(assertIsNumber, {1,2,3})
        assertError(assertIsNumber, {1})
        assertError(assertIsTable, true)
    end

    function TestLuaUnitAssertions:test_assertIsString()
        assertError(assertIsString, 1)
        assertError(assertIsString, 1.4)
        assertIsString("hi there!")
        assertError(assertIsString, nil)
        assertError(assertIsString, {})
        assertError(assertIsString, {1,2,3})
        assertError(assertIsString, {1})
        assertError(assertIsTable, true)
    end

    function TestLuaUnitAssertions:test_assertIsTable()
        assertError(assertIsTable, 1)
        assertError(assertIsTable, 1.4)
        assertError(assertIsTable, "hi there!")
        assertError(assertIsTable, nil)
        assertIsTable({})
        assertIsTable({1,2,3})
        assertIsTable({1})
        assertError(assertIsTable, true)
    end

    function TestLuaUnitAssertions:test_assertIsBoolean()
        assertError(assertIsBoolean, 1)
        assertError(assertIsBoolean, 1.4)
        assertError(assertIsBoolean, "hi there!")
        assertError(assertIsBoolean, nil)
        assertError(assertIsBoolean, {})
        assertError(assertIsBoolean, {1,2,3})
        assertError(assertIsBoolean, {1})
        assertIsBoolean(true)
        assertIsBoolean(false)
    end

    function TestLuaUnitAssertions:test_assertIsNil()
        assertError(assertIsNil, 1)
        assertError(assertIsNil, 1.4)
        assertError(assertIsNil, "hi there!")
        assertIsNil(nil)
        assertError(assertIsNil, {})
        assertError(assertIsNil, {1,2,3})
        assertError(assertIsNil, {1})
        assertError(assertIsNil, false)
    end

    function TestLuaUnitAssertions:test_assertIsFunction()
        f = function() return true end

        assertError(assertIsFunction, 1)
        assertError(assertIsFunction, 1.4)
        assertError(assertIsFunction, "hi there!")
        assertError(assertIsFunction, nil)
        assertError(assertIsFunction, {})
        assertError(assertIsFunction, {1,2,3})
        assertError(assertIsFunction, {1})
        assertError(assertIsFunction, false)
        assertIsFunction(f)
    end

    function TestLuaUnitAssertions:test_assertIs()
        local f = function() return true end
        local g = function() return true end
        local temp = {}

        assertIs(1,1)
        assertIs(f,f)
        assertIs(temp,temp)
        temp = {a=1,{1,2},day="today"}
        assertIs(temp,temp)

        assertError(assertIs, 1, 2)
        assertError(assertIs, 1.4, 1)
        assertError(assertIs, "hi there!", "hola")
        assertError(assertIs, nil, 1)
        assertError(assertIs, {}, {})
        assertError(assertIs, {1,2,3}, f)
        assertError(assertIs, f, g)
    end

    function TestLuaUnitAssertions:test_assertNotIs()
        local f = function() return true end
        local g = function() return true end
        local temp = {}

        assertError( assertNotIs, 1,1 )
        assertError( assertNotIs, f,f )
        assertError( assertNotIs, temp,temp )
        temp = {a=1,{1,2},day="today"}
        assertError( assertNotIs, temp,temp)

        assertNotIs(1, 2)
        assertNotIs(1.4, 1)
        assertNotIs("hi there!", "hola")
        assertNotIs(nil, 1)
        assertNotIs({}, {})
        assertNotIs({1,2,3}, f)
        assertNotIs(f, g)
    end

    function TestLuaUnitAssertions:test_assertTableNum()
        assertEquals( 3, 3 )
        assertNotEquals( 3, 4 )
        assertEquals( {3}, {3} )
        assertNotEquals( {3}, 3 )
        assertNotEquals( {3}, {4} )
        assertEquals( {x=1}, {x=1} )
        assertNotEquals( {x=1}, {x=2} )
        assertNotEquals( {x=1}, {y=1} )
    end
    function TestLuaUnitAssertions:test_assertTableStr()
        assertEquals( '3', '3' )
        assertNotEquals( '3', '4' )
        assertEquals( {'3'}, {'3'} )
        assertNotEquals( {'3'}, '3' )
        assertNotEquals( {'3'}, {'4'} )
        assertEquals( {x='1'}, {x='1'} )
        assertNotEquals( {x='1'}, {x='2'} )
        assertNotEquals( {x='1'}, {y='1'} )
    end
    function TestLuaUnitAssertions:test_assertTableLev2()
        assertEquals( {x={'a'}}, {x={'a'}} )
        assertNotEquals( {x={'a'}}, {x={'b'}} )
        assertNotEquals( {x={'a'}}, {z={'a'}} )
        assertEquals( {{x=1}}, {{x=1}} )
        assertNotEquals( {{x=1}}, {{y=1}} )
        assertEquals( {{x='a'}}, {{x='a'}} )
        assertNotEquals( {{x='a'}}, {{x='b'}} )
    end
    function TestLuaUnitAssertions:test_assertTableList()
        assertEquals( {3,4,5}, {3,4,5} )
        assertNotEquals( {3,4,5}, {3,4,6} )
        assertNotEquals( {3,4,5}, {3,5,4} )
        assertEquals( {3,4,x=5}, {3,4,x=5} )
        assertNotEquals( {3,4,x=5}, {3,4,x=6} )
        assertNotEquals( {3,4,x=5}, {3,x=4,5} )
        assertNotEquals( {3,4,5}, {2,3,4,5} )
        assertNotEquals( {3,4,5}, {3,2,4,5} )
        assertNotEquals( {3,4,5}, {3,4,5,6} )
    end

    function TestLuaUnitAssertions:test_assertTableNil()
        assertEquals( {3,4,5}, {3,4,5} )
        assertNotEquals( {3,4,5}, {nil,3,4,5} )
        assertNotEquals( {3,4,5}, {nil,4,5} )
        assertEquals( {3,4,5}, {3,4,5,nil} ) -- lua quirk
        assertNotEquals( {3,4,5}, {3,4,nil} )
        assertNotEquals( {3,4,5}, {3,nil,5} )
        assertNotEquals( {3,4,5}, {3,4,nil,5} )
    end
    
    function TestLuaUnitAssertions:test_assertTableNilFront()
        assertEquals( {nil,4,5}, {nil,4,5} )
        assertNotEquals( {nil,4,5}, {nil,44,55} )
        assertEquals( {nil,'4','5'}, {nil,'4','5'} )
        assertNotEquals( {nil,'4','5'}, {nil,'44','55'} )
        assertEquals( {nil,{4,5}}, {nil,{4,5}} )
        assertNotEquals( {nil,{4,5}}, {nil,{44,55}} )
        assertNotEquals( {nil,{4}}, {nil,{44}} )
        assertEquals( {nil,{x=4,5}}, {nil,{x=4,5}} )
        assertEquals( {nil,{x=4,5}}, {nil,{5,x=4}} ) -- lua quirk
        assertEquals( {nil,{x=4,y=5}}, {nil,{y=5,x=4}} ) -- lua quirk
        assertNotEquals( {nil,{x=4,5}}, {nil,{y=4,5}} )
    end

    function TestLuaUnitAssertions:test_assertTableAdditions()
        assertEquals( {1,2,3}, {1,2,3} )
        assertNotEquals( {1,2,3}, {1,2,3,4} )
        assertNotEquals( {1,2,3,4}, {1,2,3} )
        assertEquals( {1,x=2,3}, {1,x=2,3} )
        assertNotEquals( {1,x=2,3}, {1,x=2,3,y=4} )
        assertNotEquals( {1,x=2,3,y=4}, {1,x=2,3} )
    end

------------------------------------------------------------------
--
--                       Error message tests
--
------------------------------------------------------------------

function assertErrorMsg( expectedMsg, func, ... )
    -- assert that calling f with the arguments will raise an error
    -- example: assertError( f, 1, 2 ) => f(1,2) should generate an error
    local no_error, error_msg = pcall( func, ... )
    if no_error then
        error( 'No error generated but expected error: "'..expectedMsg..'"', 2 )
    end
    if error_msg ~= expectedMsg then
        error( 'Error message expected: "'..expectedMsg..'"\nError message received: "'..error_msg..'"\n')
    end
end

TestLuaUnitErrorMsg = {} --class
    TestLuaUnitErrorMsg.__class__ = 'TestLuaUnitErrorMsg'

    function TestLuaUnitErrorMsg:test_assertErrorMsgFailsWhenNoError()
        assertError( assertErrorMsg, 'toto', assertEquals, 1, 1  )
    end 

    function TestLuaUnitErrorMsg:test_assertErrorMsgFailsWhenNoError2()
        assertErrorMsg( 'expected: 2, actual: 1', assertEquals, 1, 2  )
        assertErrorMsg( 'expected: "exp"\nactual: "act"\n', assertEquals, 'act', 'exp' )
    end 



------------------------------------------------------------------
--
--                       Execution Tests 
--
------------------------------------------------------------------

TestLuaUnitExecution = {} --class

    TestLuaUnitExecution.__class__ = 'TestLuaUnitExecution'

    function TestLuaUnitExecution:tearDown()
        executedTests = {}
    end

    function TestLuaUnitExecution:setUp()
        executedTests = {}
    end

    MyTestToto1 = {} --class
        function MyTestToto1:test1() table.insert( executedTests, "MyTestToto1:test1" ) end
        function MyTestToto1:testb() table.insert( executedTests, "MyTestToto1:testb" ) end
        function MyTestToto1:test3() table.insert( executedTests, "MyTestToto1:test3" ) end
        function MyTestToto1:testa() table.insert( executedTests, "MyTestToto1:testa" ) end
        function MyTestToto1:test2() table.insert( executedTests, "MyTestToto1:test2" ) end

    MyTestWithFailures = {} --class
        function MyTestWithFailures:testWithFailure1() assertEquals(1, 2) end
        function MyTestWithFailures:testWithFailure2() assertError( function() end ) end
        function MyTestWithFailures:testOk() end

    MyTestOk = {} --class
        function MyTestOk:testOk1() end
        function MyTestOk:testOk2() end

    function TestLuaUnitExecution:test_MethodsAreExecutedInRightOrder()
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

    function TestLuaUnitExecution:testRunSomeTestByName( )
        assertEquals( #executedTests, 0 )
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'MyTestToto1' )
        assertEquals( #executedTests, 5 )
    end

    function TestLuaUnitExecution:testRunSomeTestByGlobalInstance( )
        assertEquals( #executedTests, 0 )
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'Toto', MyTestToto1 )
        assertEquals( #executedTests, 5 )
    end

    function TestLuaUnitExecution:testRunSomeTestByLocalInstance( )
        MyLocalTestToto1 = {} --class
        function MyLocalTestToto1:test1() table.insert( executedTests, "MyLocalTestToto1:test1" ) end
 
        assertEquals( #executedTests, 0 )
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'MyLocalTestToto1', MyLocalTestToto1 )
        assertEquals( #executedTests, 1 )
        assertEquals( executedTests[1], 'MyLocalTestToto1:test1')
    end

    function TestLuaUnitExecution:testRunTestByTestFunction()
        local function mytest()
            table.insert( executedTests, "mytest" )
        end

        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'mytest', mytest )
        assertEquals( #executedTests, 1 )
        assertEquals( executedTests[1], 'mytest')

    end


    function TestLuaUnitExecution:testRunReturnsNumberOfFailures()
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        ret = runner:runSuite( 'MyTestWithFailures' )
        assertEquals(ret, 2)

        ret = runner:runSuite( 'MyTestToto1' )
        assertEquals(ret, 0)
    end

    function TestLuaUnitExecution:testTestCountAndFailCount()
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuite( 'MyTestWithFailures' )
        assertEquals( runner.result.testCount, 3)
        assertEquals( runner.result.failureCount, 2)

        runner:runSuite( 'MyTestToto1' )
        assertEquals( runner.result.testCount, 5)
        assertEquals( runner.result.failureCount, 0)
    end

    function TestLuaUnitExecution:testRunTestMethod()
        local myExecutedTests = {}
        local MyTestWithSetupTeardown = {}
            function MyTestWithSetupTeardown:setUp()    table.insert( myExecutedTests, 'setUp' ) end
            function MyTestWithSetupTeardown:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupTeardown:tearDown() table.insert( myExecutedTests, 'tearDown' )  end

        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'MyTestWithSetupTeardown:test1', MyTestWithSetupTeardown )
        assertEquals( runner.result.failureCount, 0 )
        assertEquals( myExecutedTests[1], 'setUp' )   
        assertEquals( myExecutedTests[2], 'test1')
        assertEquals( myExecutedTests[3], 'tearDown')
        assertEquals( #myExecutedTests, 3)
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors1()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ); assertEquals( 'b', 'c') end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' )  end

        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'MyTestWithSetupError', MyTestWithSetupError )
        assertEquals( runner.result.failureCount, 1 )
        assertEquals( runner.result.testCount, 1 )
        assertEquals( myExecutedTests[1], 'setUp' )   
        assertEquals( myExecutedTests[2], 'tearDown')
        assertEquals( #myExecutedTests, 2)
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors2()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ) end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ); assertEquals( 'b', 'c')   end

        runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'MyTestWithSetupError', MyTestWithSetupError )
        assertEquals( runner.result.failureCount, 1 )
        assertEquals( runner.result.testCount, 1 )
        assertEquals( myExecutedTests[1], 'setUp' )   
        assertEquals( myExecutedTests[2], 'test1' )   
        assertEquals( myExecutedTests[3], 'tearDown')
        assertEquals( #myExecutedTests, 3)
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors3()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ); assertEquals( 'b', 'c') end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ); assertEquals( 'b', 'c')   end

        runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'MyTestWithSetupError', MyTestWithSetupError )
        assertEquals( runner.result.failureCount, 1 )
        assertEquals( runner.result.testCount, 1 )
        assertEquals( myExecutedTests[1], 'setUp' )   
        assertEquals( myExecutedTests[2], 'tearDown')
        assertEquals( #myExecutedTests, 2)
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors4()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ); assertEquals( 'b', 'c') end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ); assertEquals( 'b', 'c')  end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ); assertEquals( 'b', 'c')   end

        runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'MyTestWithSetupError', MyTestWithSetupError )
        assertEquals( runner.result.failureCount, 1 )
        assertEquals( runner.result.testCount, 1 )
        assertEquals( myExecutedTests[1], 'setUp' )   
        assertEquals( myExecutedTests[2], 'tearDown')
        assertEquals( #myExecutedTests, 2)
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors5()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ) end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ); assertEquals( 'b', 'c')  end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ); assertEquals( 'b', 'c')   end

        runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'MyTestWithSetupError', MyTestWithSetupError )
        assertEquals( runner.result.failureCount, 1 )
        assertEquals( runner.result.testCount, 1 )
        assertEquals( myExecutedTests[1], 'setUp' )   
        assertEquals( myExecutedTests[2], 'test1' )   
        assertEquals( myExecutedTests[3], 'tearDown')
        assertEquals( #myExecutedTests, 3)
    end

    function TestLuaUnitExecution:testOutputInterface()
        local runner = LuaUnit:new()
        runner.outputType = Mock
        runner:runSuite( 'MyTestWithFailures', 'MyTestOk' )
        m = runner.output

        assertEquals( m.calls[1][1], 'startSuite' )
        assertEquals(#m.calls[1], 2 )

        assertEquals( m.calls[2][1], 'startClass' )
        assertEquals( m.calls[2][3], 'MyTestWithFailures' )
        assertEquals(#m.calls[2], 3 )

        assertEquals( m.calls[3][1], 'startTest' )
        assertEquals( m.calls[3][3], 'MyTestWithFailures:testOk' )
        assertEquals(#m.calls[3], 3 )

        assertEquals( m.calls[4][1], 'endTest' )
        assertEquals( m.calls[4][3], false )
        assertEquals(#m.calls[4], 3 )

        assertEquals( m.calls[5][1], 'startTest' )
        assertEquals( m.calls[5][3], 'MyTestWithFailures:testWithFailure1' )
        assertEquals(#m.calls[5], 3 )

        assertEquals( m.calls[6][1], 'addFailure' )
        assertEquals(#m.calls[6], 4 )

        assertEquals( m.calls[7][1], 'endTest' )
        assertEquals( m.calls[7][3], true )
        assertEquals(#m.calls[7], 3 )


        assertEquals( m.calls[8][1], 'startTest' )
        assertEquals( m.calls[8][3], 'MyTestWithFailures:testWithFailure2' )
        assertEquals(#m.calls[8], 3 )

        assertEquals( m.calls[9][1], 'addFailure' )
        assertEquals(#m.calls[9], 4 )

        assertEquals( m.calls[10][1], 'endTest' )
        assertEquals( m.calls[10][3], true )
        assertEquals(#m.calls[10], 3 )

        assertEquals( m.calls[11][1], 'endClass' )
        assertEquals(#m.calls[11], 2 )

        assertEquals( m.calls[12][1], 'startClass' )
        assertEquals( m.calls[12][3], 'MyTestOk' )
        assertEquals(#m.calls[12], 3 )

        assertEquals( m.calls[13][1], 'startTest' )
        assertEquals( m.calls[13][3], 'MyTestOk:testOk1' )
        assertEquals(#m.calls[13], 3 )

        assertEquals( m.calls[14][1], 'endTest' )
        assertEquals( m.calls[14][3], false )
        assertEquals(#m.calls[14], 3 )

        assertEquals( m.calls[15][1], 'startTest' )
        assertEquals( m.calls[15][3], 'MyTestOk:testOk2' )
        assertEquals(#m.calls[15], 3 )

        assertEquals( m.calls[16][1], 'endTest' )
        assertEquals( m.calls[16][3], false )
        assertEquals(#m.calls[16], 3 )

        assertEquals( m.calls[17][1], 'endClass' )
        assertEquals(#m.calls[17], 2 )

        assertEquals( m.calls[18][1], 'endSuite' )
        assertEquals(#m.calls[18], 2 )

        assertEquals( m.calls[19], nil )

    end

LuaUnit.verbosity = 2
os.exit( LuaUnit:run() )
