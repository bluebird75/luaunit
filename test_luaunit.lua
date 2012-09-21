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

function printSeq( seq )
    if type(seq) ~= 'table' then
        print( mytostring(seq) )
        return
    end

    for i,v in ipairs(seq) do
        print( '['..i..']: '..mytostring(v) )
    end
end


TestLuaUnit = {} --class

    TestLuaUnit.__class__ = 'TestLuaUnit'

    function TestLuaUnit:tearDown()
        executedTests = {}
    end

    function TestLuaUnit:setUp()
        executedTests = {}
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

    function TestLuaUnit:test_strSplitOneCharDelim()
        t = strsplit( '\n', '1\n22\n333\n' )
        assertEquals( t[1], '1')
        assertEquals( t[2], '22')
        assertEquals( t[3], '333')
        assertEquals( t[4], '')
        assertEquals( #t, 4 )
    end

    function TestLuaUnit:test_strSplit3CharDelim()
        t = strsplit( '2\n3', '1\n22\n332\n3' )
        assertEquals( t[1], '1\n2')
        assertEquals( t[2], '3')
        assertEquals( t[3], '')
        assertEquals( #t, 3 )
    end

    function TestLuaUnit:test_strSplitOnFailure()
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

    MyTestWithFailures = {}
        function MyTestWithFailures:testWithFailure1() assertEquals(1, 2) end
        function MyTestWithFailures:testWithFailure2() assertError( function() end ) end
        function MyTestWithFailures:testOk() end

    MyTestOk = {}
        function MyTestOk:testOk1() end
        function MyTestOk:testOk2() end

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

    function TestLuaUnit:testRunSomeTestByName( )
        assertEquals( #executedTests, 0 )
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'MyTestToto1' )
        assertEquals( #executedTests, 5 )
    end

    function TestLuaUnit:testRunSomeTestByGlobalInstance( )
        assertEquals( #executedTests, 0 )
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'Toto', MyTestToto1 )
        assertEquals( #executedTests, 5 )
    end

    function TestLuaUnit:testRunSomeTestByLocalInstance( )
        MyLocalTestToto1 = {} --class
        function MyLocalTestToto1:test1() table.insert( executedTests, "MyLocalTestToto1:test1" ) end
 
        assertEquals( #executedTests, 0 )
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'MyLocalTestToto1', MyLocalTestToto1 )
        assertEquals( #executedTests, 1 )
        assertEquals( executedTests[1], 'MyLocalTestToto1:test1')
    end

    function TestLuaUnit:testRunTestByTestFunction()
        local function mytest()
            table.insert( executedTests, "mytest" )
        end

        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSomeTest( 'mytest', mytest )
        assertEquals( #executedTests, 1 )
        assertEquals( executedTests[1], 'mytest')

    end


    function TestLuaUnit:testRunReturnsNumberOfFailures()
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        ret = runner:runSuite( 'MyTestWithFailures' )
        assertEquals(ret, 2)

        ret = runner:runSuite( 'MyTestToto1' )
        assertEquals(ret, 0)
    end

    function TestLuaUnit:testTestCountAndFailCount()
        local runner = LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuite( 'MyTestWithFailures' )
        assertEquals( runner.result.testCount, 3)
        assertEquals( runner.result.failureCount, 2)

        runner:runSuite( 'MyTestToto1' )
        assertEquals( runner.result.testCount, 5)
        assertEquals( runner.result.failureCount, 0)
    end

    function TestLuaUnit:testRunTestMethod()
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

    function TestLuaUnit:testWithSetupTeardownErrors1()
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

    function TestLuaUnit:testWithSetupTeardownErrors2()
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

    function TestLuaUnit:testWithSetupTeardownErrors3()
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

    function TestLuaUnit:testWithSetupTeardownErrors4()
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

    function TestLuaUnit:testWithSetupTeardownErrors5()
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

    function TestLuaUnit:testOutputInterface()
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
LuaUnit.verbosity = 2
-- LuaUnit:run( 'TestMock', 'TestLuaUnit:testRunSomeTestByName')
LuaUnit:run()

--[[ More tests ]]
-- strip luaunit stack more intelligently
-- table assertions
-- better verbosity support
-- assert contains
-- more user documentation
-- compatibilty tests with several version of lua
-- real test for wrapFunctions
-- sequence asserts
-- display time to run all tests
-- make sure test suite ends when running tests with RunByTestClass or RunByTestMethod
-- add assertNotEquals
-- add assertAlmonstEquals for floats
-- add assertContains for strings
