--[[ 
Author: Philippe Fremy <phil@freehackers.org>
License: BSD License, see LICENSE.txt

]]--

-- This is a bit tricky since the test uses the features that it tests.

lu = require('luaunit')

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
        lu.assertEquals(  m.calls[1][1], 'titi' )
        lu.assertEquals(  m.calls[1][2], 42 )
        lu.assertEquals( #m.calls[1], 2 )

        lu.assertEquals(  m.calls[2][1], 'toto' )
        lu.assertEquals(  m.calls[2][2], 33 )
        lu.assertEquals(  m.calls[2][3], 'abc' )
        lu.assertEquals(  m.calls[2][4][1], 21 )
        lu.assertEquals( #m.calls[2], 4 )

        lu.assertEquals( #m.calls, 2 )
    end

------------------------------------------------------------------
--
--                      Utility Tests              
--
------------------------------------------------------------------

TestLuaUnitUtilities = {} --class

    TestLuaUnitUtilities.__class__ = 'TestLuaUnitUtilities'


    function TestLuaUnitUtilities:test_genSortedIndex()
        lu.assertEquals( lu.private.__genSortedIndex( { 2, 5, 7} ), {1,2,3} )
        lu.assertEquals( lu.private.__genSortedIndex( { a='1', h='2', c='3' } ), {'a', 'c', 'h'} )
        lu.assertEquals( lu.private.__genSortedIndex( { 1, 'z', a='1', h='2', c='3' } ), { 1, 2, 'a', 'c', 'h' } )
    end

    function TestLuaUnitUtilities:test_sortedNextReturnsSortedKeyValues()
        t1 = {}
        t1['aaa'] = 'abc'
        t1['ccc'] = 'def'
        t1['bbb'] = 'cba'

        k, v = lu.private.sortedNext( t1, nil )
        lu.assertEquals( k, 'aaa' )
        lu.assertEquals( v, 'abc' )
        k, v = lu.private.sortedNext( t1, k )
        lu.assertEquals( k, 'bbb' )
        lu.assertEquals( v, 'cba' )
        k, v = lu.private.sortedNext( t1, k )
        lu.assertEquals( k, 'ccc' )
        lu.assertEquals( v, 'def' )
        k, v = lu.private.sortedNext( t1, k )
        lu.assertEquals( k, nil )
        lu.assertEquals( v, nil )
    end

    function TestLuaUnitUtilities:test_sortedNextWorksTwiceOnTable()
        t1 = {}
        t1['aaa'] = 'abc'
        t1['ccc'] = 'def'
        t1['bbb'] = 'cba'

        k, v = lu.private.sortedNext( t1, nil )
        k, v = lu.private.sortedNext( t1, k )
        k, v = lu.private.sortedNext( t1, nil )
        lu.assertEquals( k, 'aaa' )
        lu.assertEquals( v, 'abc' )
    end

    function TestLuaUnitUtilities:test_sortedNextWorksOnTwoTables()
        t1 = { aaa = 'abc', ccc = 'def' }
        t2 = { ['3'] = '33', ['1'] = '11' }

        k, v = lu.private.sortedNext( t1, nil )
        lu.assertEquals( k, 'aaa' )
        lu.assertEquals( v, 'abc' )

        k, v = lu.private.sortedNext( t2, nil )
        lu.assertEquals( k, '1' )
        lu.assertEquals( v, '11' )

        k, v = lu.private.sortedNext( t1, 'aaa' )
        lu.assertEquals( k, 'ccc' )
        lu.assertEquals( v, 'def' )

        k, v = lu.private.sortedNext( t2, '1' )
        lu.assertEquals( k, '3' )
        lu.assertEquals( v, '33' )
    end

    function TestLuaUnitUtilities:test_strSplitOneCharDelim()
        t = lu.private.strsplit( '\n', '1\n22\n333\n' )
        lu.assertEquals( t[1], '1')
        lu.assertEquals( t[2], '22')
        lu.assertEquals( t[3], '333')
        lu.assertEquals( t[4], '')
        lu.assertEquals( #t, 4 )
    end

    function TestLuaUnitUtilities:test_strSplit3CharDelim()
        t = lu.private.strsplit( '2\n3', '1\n22\n332\n3' )
        lu.assertEquals( t[1], '1\n2')
        lu.assertEquals( t[2], '3')
        lu.assertEquals( t[3], '')
        lu.assertEquals( #t, 3 )
    end

    function TestLuaUnitUtilities:test_strSplitOnFailure()
        s1 = 'd:/work/luaunit/luaunit-git/luaunit/test_luaunit.lua:467: expected: 1, actual: 2\n'
        s2 = [[stack traceback:
    .\luaunit.lua:443: in function <.\luaunit.lua:442>
    [C]: in function 'error'
    .\luaunit.lua:56: in function 'lu.assertEquals'
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
        local SPLITTER = '\n>----------<\n'
        local t = lu.private.strsplit( SPLITTER, s1..SPLITTER..s2)
        lu.assertEquals( t[1], s1)
        lu.assertEquals( t[2], s2)
        lu.assertEquals( #t, 2 )
    end

    function TestLuaUnitUtilities:test_prefixString()
        lu.assertEquals( lu.private.prefixString( '12 ', 'ab\ncd\nde'), '12 ab\n12 cd\n12 de' )
    end


    function TestLuaUnitUtilities:test_table_keytostring()
        lu.assertEquals( table.keytostring( 'a' ), 'a' )
        lu.assertEquals( table.keytostring( 'a0' ), 'a0' )
        lu.assertEquals( table.keytostring( 'a0!' ), '"a0!"' )
    end

    function TestLuaUnitUtilities:test_prettystr()
        lu.assertEquals( lu.prettystr( 1 ), "1" )
        lu.assertEquals( lu.prettystr( 1.1 ), "1.1" )
        lu.assertEquals( lu.prettystr( 'abc' ), '"abc"' )
        lu.assertEquals( lu.prettystr( 'ab\ncd' ), '"ab\ncd"' )
        lu.assertEquals( lu.prettystr( 'ab\ncd', true ), '"ab\\ncd"' )
        lu.assertEquals( lu.prettystr( 'ab"cd' ), "'ab\"cd'" )
        lu.assertEquals( lu.prettystr( "ab'cd" ), '"ab\'cd"' )
        lu.assertStrContains( lu.prettystr( {1,2,3} ), "{1, 2, 3}" )
        lu.assertStrContains( lu.prettystr( {a=1,bb=2,ab=3} ), '{a=1, ab=3, bb=2}' )
    end

    function TestLuaUnitUtilities:test_prettystr_adv_tables()
        local t1 = {1,2,3,4,5,6}
        lu.assertEquals(lu.prettystr(t1), "{1, 2, 3, 4, 5, 6}" )

        local t2 = {'aaaaaaaaaaaaaaaaa', 'bbbbbbbbbbbbbbbbbbbb', 'ccccccccccccccccc', 'ddddddddddddd', 'eeeeeeeeeeeeeeeeee', 'ffffffffffffffff', 'ggggggggggg', 'hhhhhhhhhhhhhh'}
        lu.assertEquals(lu.prettystr(t2), table.concat( {
            '{',
            '    "aaaaaaaaaaaaaaaaa",',
            '    "bbbbbbbbbbbbbbbbbbbb",',
            '    "ccccccccccccccccc",',
            '    "ddddddddddddd",',
            '    "eeeeeeeeeeeeeeeeee",',
            '    "ffffffffffffffff",',
            '    "ggggggggggg",',
            '    "hhhhhhhhhhhhhh"',
            '}',
        } , '\n' ) )

        local t2bis = { 1,2,3,'12345678901234567890123456789012345678901234567890123456789012345678901234567890', 4,5,6 }
        lu.assertEquals(lu.prettystr(t2bis), [[{
    1,
    2,
    3,
    "12345678901234567890123456789012345678901234567890123456789012345678901234567890",
    4,
    5,
    6
}]] )

        local t3 = { l1a = { l2a = { l3a='012345678901234567890123456789012345678901234567890123456789' }, 
        l2b='bbb' }, l1b = 4}
        lu.assertEquals(lu.prettystr(t3), [[{
    l1a={
        l2a={l3a="012345678901234567890123456789012345678901234567890123456789"},
        l2b="bbb"
    },
    l1b=4
}]] )

        local t4 = { a=1, b=2, c=3 }
        lu.assertEquals(lu.prettystr(t4), '{a=1, b=2, c=3}' )

        local t5 = { t1, t2, t3 }
        lu.assertEquals( lu.prettystr(t5), [[{
    {1, 2, 3, 4, 5, 6},
    {
        "aaaaaaaaaaaaaaaaa",
        "bbbbbbbbbbbbbbbbbbbb",
        "ccccccccccccccccc",
        "ddddddddddddd",
        "eeeeeeeeeeeeeeeeee",
        "ffffffffffffffff",
        "ggggggggggg",
        "hhhhhhhhhhhhhh"
    },
    {
        l1a={
            l2a={l3a="012345678901234567890123456789012345678901234567890123456789"},
            l2b="bbb"
        },
        l1b=4
    }
}]] )

        local t6 = { t1=t1, t2=t2, t3=t3, t4=t4 }
        lu.assertEquals(lu.prettystr(t6),[[{
    t1={1, 2, 3, 4, 5, 6},
    t2={
        "aaaaaaaaaaaaaaaaa",
        "bbbbbbbbbbbbbbbbbbbb",
        "ccccccccccccccccc",
        "ddddddddddddd",
        "eeeeeeeeeeeeeeeeee",
        "ffffffffffffffff",
        "ggggggggggg",
        "hhhhhhhhhhhhhh"
    },
    t3={
        l1a={
            l2a={l3a="012345678901234567890123456789012345678901234567890123456789"},
            l2b="bbb"
        },
        l1b=4
    },
    t4={a=1, b=2, c=3}
}]])
    end

    function TestLuaUnitUtilities:test_prettstrTableRecursion()
        local t = {}
        t.__index = t
        lu.assertStrMatches(lu.prettystr(t), "<table: 0?x?[%x]+> {__index=<table: 0?x?[%x]+>}")

        local t1 = {}
        local t2 = {}
        t1.t2 = t2
        t2.t1 = t1
        local t3 = { t1 = t1, t2 = t2 }
        lu.assertStrMatches(lu.prettystr(t1), "<table: 0?x?[%x]+> {t2=<table: 0?x?[%x]+> {t1=<table: 0?x?[%x]+>}}")
        lu.assertStrMatches(lu.prettystr(t3), [[<table: 0?x?[%x]+> {
    t1=<table: 0?x?[%x]+> {t2=<table: 0?x?[%x]+> {t1=<table: 0?x?[%x]+>}},
    t2=<table: 0?x?[%x]+>
}]])

        local t4 = {1,2}
        local t5 = {3,4,t4}
        t4[3] = t5
        lu.assertStrMatches(lu.prettystr(t5), "<table: 0?x?[%x]+> {3, 4, <table: 0?x?[%x]+> {1, 2, <table: 0?x?[%x]+>}}")
    end

    function TestLuaUnitUtilities:test_IsFunction()
        lu.assertEquals( lu.LuaUnit.isFunction( function (a,b) end ), true )
        lu.assertEquals( lu.LuaUnit.isFunction( nil ), false )
    end

    function TestLuaUnitUtilities:test_IsClassMethod()
        lu.assertEquals( lu.LuaUnit.isClassMethod( 'toto' ), false )
        lu.assertEquals( lu.LuaUnit.isClassMethod( 'toto.titi' ), true )
    end

    function TestLuaUnitUtilities:test_splitClassMethod()
        lu.assertEquals( lu.LuaUnit.splitClassMethod( 'toto' ), nil )
        v1, v2 = lu.LuaUnit.splitClassMethod( 'toto.titi' )
        lu.assertEquals( {v1, v2}, {'toto', 'titi'} )
    end

    function TestLuaUnitUtilities:test_isTestName()
        lu.assertEquals( lu.LuaUnit.isTestName( 'testToto' ), true )
        lu.assertEquals( lu.LuaUnit.isTestName( 'TestToto' ), true )
        lu.assertEquals( lu.LuaUnit.isTestName( 'TESTToto' ), true )
        lu.assertEquals( lu.LuaUnit.isTestName( 'xTESTToto' ), false )
        lu.assertEquals( lu.LuaUnit.isTestName( '' ), false )
    end

    function TestLuaUnitUtilities:test_parseCmdLine()
        --test names
        lu.assertEquals( lu.LuaUnit.parseCmdLine(), {} )
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { 'someTest' } ), { testNames={'someTest'} } )
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { 'someTest', 'someOtherTest' } ), { testNames={'someTest', 'someOtherTest'} } )

        -- verbosity
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { '--verbose' } ), { verbosity=lu.VERBOSITY_VERBOSE } )
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { '-v' } ), { verbosity=lu.VERBOSITY_VERBOSE } )
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { '--quiet' } ), { verbosity=lu.VERBOSITY_QUIET } )
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { '-q' } ), { verbosity=lu.VERBOSITY_QUIET } )
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { '-v', '-q' } ), { verbosity=lu.VERBOSITY_QUIET } )

        --output
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { '--output', 'toto' } ), { output='toto'} )
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { '-o', 'toto' } ), { output='toto'} )
        lu.assertErrorMsgContains( 'Missing argument after -o', lu.LuaUnit.parseCmdLine, { '-o', } )

        --name
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { '--name', 'toto' } ), { fname='toto'} )
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { '-n', 'toto' } ), { fname='toto'} )
        lu.assertErrorMsgContains( 'Missing argument after -n', lu.LuaUnit.parseCmdLine, { '-n', } )

        --patterns
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { '--pattern', 'toto' } ), { pattern={'toto'} } )
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { '-p', 'toto' } ), { pattern={'toto'} } )
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { '-p', 'titi', '-p', 'toto' } ), { pattern={'titi', 'toto'} } )
        lu.assertErrorMsgContains( 'Missing argument after -p', lu.LuaUnit.parseCmdLine, { '-p', } )

        --megamix
        lu.assertEquals( lu.LuaUnit.parseCmdLine( { '-p', 'toto', 'titi', '-v', 'tata', '-o', 'tintin', '-p', 'tutu', 'prout', '-n', 'toto.xml' } ), 
            { pattern={'toto', 'tutu'}, verbosity=lu.VERBOSITY_VERBOSE, output='tintin', testNames={'titi', 'tata', 'prout'}, fname='toto.xml' } )

        lu.assertErrorMsgContains( 'option: -x', lu.LuaUnit.parseCmdLine, { '-x', } )
    end

    function TestLuaUnitUtilities:test_includePattern()
        lu.assertEquals( lu.LuaUnit.patternInclude( nil, 'toto'), true )
        lu.assertEquals( lu.LuaUnit.patternInclude( {}, 'toto'), false  )
        lu.assertEquals( lu.LuaUnit.patternInclude( {'toto'}, 'toto'), true )
        lu.assertEquals( lu.LuaUnit.patternInclude( {'toto'}, 'yyytotoxxx'), true )
        lu.assertEquals( lu.LuaUnit.patternInclude( {'titi', 'toto'}, 'yyytotoxxx'), true )
        lu.assertEquals( lu.LuaUnit.patternInclude( {'titi', 'to..'}, 'yyytoxxx'), true )
    end

    function TestLuaUnitUtilities:test_applyPatternFilter()
        myTestToto1Value = { 'MyTestToto1.test1', MyTestToto1 }

        included, excluded = lu.LuaUnit.applyPatternFilter( nil, { myTestToto1Value } )
        lu.assertEquals( excluded, {} )
        lu.assertEquals( included, { myTestToto1Value } )

        included, excluded = lu.LuaUnit.applyPatternFilter( {'T.to'}, { myTestToto1Value } )
        lu.assertEquals( excluded, {} )
        lu.assertEquals( included, { myTestToto1Value } )

        included, excluded = lu.LuaUnit.applyPatternFilter( {'T.ti'}, { myTestToto1Value } )
        lu.assertEquals( excluded, { myTestToto1Value } )
        lu.assertEquals( included, {} )
    end

    function TestLuaUnitUtilities:test_strMatch()
        lu.assertEquals( lu.private.strMatch('toto', 't.t.'), true )
        lu.assertEquals( lu.private.strMatch('toto', 't.t.', 1, 4), true )
        lu.assertEquals( lu.private.strMatch('toto', 't.t.', 2, 5), false )
        lu.assertEquals( lu.private.strMatch('toto', '.t.t.'), false )
        lu.assertEquals( lu.private.strMatch('ototo', 't.t.'), false )
        lu.assertEquals( lu.private.strMatch('totot', 't.t.'), false )
        lu.assertEquals( lu.private.strMatch('ototot', 't.t.'), false )
        lu.assertEquals( lu.private.strMatch('ototot', 't.t.',2,3), false )
        lu.assertEquals( lu.private.strMatch('ototot', 't.t.',2,5), true  )
        lu.assertEquals( lu.private.strMatch('ototot', 't.t.',2,6), false )
    end

    function TestLuaUnitUtilities:test_expandOneClass()
        local result = {}
        lu.LuaUnit.expandOneClass( result, 'titi', {} )
        lu.assertEquals( result, {} )

        result = {}
        lu.LuaUnit.expandOneClass( result, 'MyTestToto1', MyTestToto1 )
        lu.assertEquals( result, { 
            {'MyTestToto1.test1', MyTestToto1 },
            {'MyTestToto1.test2', MyTestToto1 },
            {'MyTestToto1.test3', MyTestToto1 },
            {'MyTestToto1.testa', MyTestToto1 },
            {'MyTestToto1.testb', MyTestToto1 },
        } )
    end

    function TestLuaUnitUtilities:test_expandClasses()
        local result = {}
        result = lu.LuaUnit.expandClasses( {} )
        lu.assertEquals( result, {} )

        result = lu.LuaUnit.expandClasses( { { 'MyTestFunction', MyTestFunction } } )
        lu.assertEquals( result, { { 'MyTestFunction', MyTestFunction } } )

        result = lu.LuaUnit.expandClasses( { { 'MyTestToto1.test1', MyTestToto1 } } )
        lu.assertEquals( result, { { 'MyTestToto1.test1', MyTestToto1 } } )

        result = lu.LuaUnit.expandClasses( { { 'MyTestToto1', MyTestToto1 } } )
        lu.assertEquals( result, { 
            {'MyTestToto1.test1', MyTestToto1 },
            {'MyTestToto1.test2', MyTestToto1 },
            {'MyTestToto1.test3', MyTestToto1 },
            {'MyTestToto1.testa', MyTestToto1 },
            {'MyTestToto1.testb', MyTestToto1 },
        } )
    end

    function TestLuaUnitUtilities:test_xmlEscape()
        lu.assertEquals( lu.private.xmlEscape( 'abc' ), 'abc' )
        lu.assertEquals( lu.private.xmlEscape( 'a"bc' ), 'a&quot;bc' )
        lu.assertEquals( lu.private.xmlEscape( "a'bc" ), 'a&apos;bc' )
        lu.assertEquals( lu.private.xmlEscape( "a<b&c>" ), 'a&lt;b&amp;c&gt;' )
    end

    function TestLuaUnitUtilities:test_xmlCDataEscape()
        lu.assertEquals( lu.private.xmlCDataEscape( 'abc' ), 'abc' )
        lu.assertEquals( lu.private.xmlCDataEscape( 'a"bc' ), 'a"bc' )
        lu.assertEquals( lu.private.xmlCDataEscape( "a'bc" ), "a'bc" )
        lu.assertEquals( lu.private.xmlCDataEscape( "a<b&c>" ), 'a<b&c>' )
        lu.assertEquals( lu.private.xmlCDataEscape( "a<b]]>--" ), 'a<b]]&gt;--' )
    end

    function TestLuaUnitUtilities:test_hasNewline()
        lu.assertEquals( lu.private.hasNewLine(''), false )
        lu.assertEquals( lu.private.hasNewLine('abc'), false )
        lu.assertEquals( lu.private.hasNewLine('ab\nc'), true )
    end

    function TestLuaUnitUtilities:test_stripStackTrace()
        local realStackTrace=[[stack traceback:
        example_with_luaunit.lua:130: in function 'test2_withFailure'
        ./luaunit.lua:1449: in function <./luaunit.lua:1449>
        [C]: in function 'xpcall'
        ./luaunit.lua:1449: in function 'protectedCall'
        ./luaunit.lua:1508: in function 'execOneFunction'
        ./luaunit.lua:1596: in function 'runSuiteByInstances'
        ./luaunit.lua:1660: in function 'runSuiteByNames'
        ./luaunit.lua:1736: in function 'runSuite'
        example_with_luaunit.lua:140: in main chunk
        [C]: in ?]]


        local realStackTrace2=[[stack traceback:
        ./luaunit.lua:545: in function 'lu.assertEquals'
        example_with_luaunit.lua:58: in function 'TestToto.test7'
        ./luaunit.lua:1517: in function <./luaunit.lua:1517>
        [C]: in function 'xpcall'
        ./luaunit.lua:1517: in function 'protectedCall'
        ./luaunit.lua:1578: in function 'execOneFunction'
        ./luaunit.lua:1677: in function 'runSuiteByInstances'
        ./luaunit.lua:1730: in function 'runSuiteByNames'
        ./luaunit.lua:1806: in function 'runSuite'
        example_with_luaunit.lua:140: in main chunk
        [C]: in ?]]

        local realStackTrace3 = [[stack traceback:
        luaunit2/example_with_luaunit.lua:124: in function 'test1_withFailure'
        luaunit2/luaunit.lua:1532: in function <luaunit2/luaunit.lua:1532>
        [C]: in function 'xpcall'
        luaunit2/luaunit.lua:1532: in function 'protectedCall'
        luaunit2/luaunit.lua:1591: in function 'execOneFunction'
        luaunit2/luaunit.lua:1679: in function 'runSuiteByInstances'
        luaunit2/luaunit.lua:1743: in function 'runSuiteByNames'
        luaunit2/luaunit.lua:1819: in function 'runSuite'
        luaunit2/example_with_luaunit.lua:140: in main chunk
        [C]: in ?]]


        local strippedStackTrace=lu.private.stripLuaunitTrace( realStackTrace )
        -- print( strippedStackTrace )

        local expectedStackTrace=[[stack traceback:
        example_with_luaunit.lua:130: in function 'test2_withFailure']]
        lu.assertEquals( strippedStackTrace, expectedStackTrace )

        strippedStackTrace=lu.private.stripLuaunitTrace( realStackTrace2 )
        expectedStackTrace=[[stack traceback:
        example_with_luaunit.lua:58: in function 'TestToto.test7']]
        lu.assertEquals( strippedStackTrace, expectedStackTrace )

        strippedStackTrace=lu.private.stripLuaunitTrace( realStackTrace3 )
        expectedStackTrace=[[stack traceback:
        luaunit2/example_with_luaunit.lua:124: in function 'test1_withFailure']]
        lu.assertEquals( strippedStackTrace, expectedStackTrace )


    end
------------------------------------------------------------------
--
--                  Assertion Tests              
--
------------------------------------------------------------------

TestLuaUnitAssertions = {} --class

    TestLuaUnitAssertions.__class__ = 'TestLuaUnitAssertions'

    function TestLuaUnitAssertions:test_assertEquals()
        f = function() return true end
        g = function() return true end
        
        lu.assertEquals( 1, 1 )
        lu.assertEquals( "abc", "abc" )
        lu.assertEquals( nil, nil )
        lu.assertEquals( true, true )
        lu.assertEquals( f, f)
        lu.assertEquals( {1,2,3}, {1,2,3})
        lu.assertEquals( {one=1,two=2,three=3}, {one=1,two=2,three=3})
        lu.assertEquals( {one=1,two=2,three=3}, {two=2,three=3,one=1})
        lu.assertEquals( {one=1,two={1,2},three=3}, {two={1,2},three=3,one=1})
        lu.assertEquals( {one=1,two={1,{2,nil}},three=3}, {two={1,{2,nil}},three=3,one=1})
        lu.assertEquals( {nil}, {nil} )

        lu.assertError( lu.assertEquals, 1, 2)
        lu.assertError( lu.assertEquals, 1, "abc" )
        lu.assertError( lu.assertEquals, 0, nil )
        lu.assertError( lu.assertEquals, false, nil )
        lu.assertError( lu.assertEquals, true, 1 )
        lu.assertError( lu.assertEquals, f, 1 )
        lu.assertError( lu.assertEquals, f, g )
        lu.assertError( lu.assertEquals, {1,2,3}, {2,1,3} )
        lu.assertError( lu.assertEquals, {1,2,3}, nil )
        lu.assertError( lu.assertEquals, {1,2,3}, 1 )
        lu.assertError( lu.assertEquals, {1,2,3}, true )
        lu.assertError( lu.assertEquals, {1,2,3}, {one=1,two=2,three=3} )
        lu.assertError( lu.assertEquals, {1,2,3}, {one=1,two=2,three=3,four=4} )
        lu.assertError( lu.assertEquals, {one=1,two=2,three=3}, {2,1,3} )
        lu.assertError( lu.assertEquals, {one=1,two=2,three=3}, nil )
        lu.assertError( lu.assertEquals, {one=1,two=2,three=3}, 1 )
        lu.assertError( lu.assertEquals, {one=1,two=2,three=3}, true )
        lu.assertError( lu.assertEquals, {one=1,two=2,three=3}, {1,2,3} )
        lu.assertError( lu.assertEquals, {one=1,two={1,2},three=3}, {two={2,1},three=3,one=1})
    end

    function TestLuaUnitAssertions:test_assertAlmostEquals()
        lu.assertAlmostEquals( 1, 1, 0.1 )

        lu.assertAlmostEquals( 1, 1.1, 0.2 )
        lu.assertAlmostEquals( -1, -1.1, 0.2 )
        lu.assertAlmostEquals( 0.1, -0.1, 0.3 )

        lu.assertAlmostEquals( 1, 1.1, 0.1 )
        lu.assertAlmostEquals( -1, -1.1, 0.1 )
        lu.assertAlmostEquals( 0.1, -0.1, 0.2 )

        lu.assertError( lu.assertAlmostEquals, 1, 1.11, 0.1 )
        lu.assertError( lu.assertAlmostEquals, -1, -1.11, 0.1 )
        lu.assertError( lu.assertAlmostEquals, -1, 1, nil )
        lu.assertError( lu.assertAlmostEquals, -1, nil, 0 )
        lu.assertError( lu.assertAlmostEquals, 1, 1.1, 0 )
        lu.assertError( lu.assertAlmostEquals, 1, 1.1, -0.1 )
    end

    function TestLuaUnitAssertions:test_assertNotEquals()
        f = function() return true end
        g = function() return true end

        lu.assertNotEquals( 1, 2 )
        lu.assertNotEquals( "abc", 2 )
        lu.assertNotEquals( "abc", "def" )
        lu.assertNotEquals( 1, 2)
        lu.assertNotEquals( 1, "abc" )
        lu.assertNotEquals( 0, nil )
        lu.assertNotEquals( false, nil )
        lu.assertNotEquals( true, 1 )
        lu.assertNotEquals( f, 1 )
        lu.assertNotEquals( f, g )
        lu.assertNotEquals( {one=1,two=2,three=3}, true )
        lu.assertNotEquals( {one=1,two={1,2},three=3}, {two={2,1},three=3,one=1} )

        lu.assertError( lu.assertNotEquals, 1, 1)
        lu.assertError( lu.assertNotEquals, "abc", "abc" )
        lu.assertError( lu.assertNotEquals, nil, nil )
        lu.assertError( lu.assertNotEquals, true, true )
        lu.assertError( lu.assertNotEquals, f, f)
        lu.assertError( lu.assertNotEquals, {one=1,two={1,{2,nil}},three=3}, {two={1,{2,nil}},three=3,one=1})
    end

    function TestLuaUnitAssertions:test_assertNotAlmostEquals()
        lu.assertNotAlmostEquals( 1, 1.2, 0.1 )

        lu.assertNotAlmostEquals( 1, 1.3, 0.2 )
        lu.assertNotAlmostEquals( -1, -1.3, 0.2 )
        lu.assertNotAlmostEquals( 0.1, -0.1, 0.1 )

        lu.assertNotAlmostEquals( 1, 1.1, 0.09 )
        lu.assertNotAlmostEquals( -1, -1.1, 0.09 )
        lu.assertNotAlmostEquals( 0.1, -0.1, 0.11 )

        lu.assertError( lu.assertNotAlmostEquals, 1, 1.11, 0.2 )
        lu.assertError( lu.assertNotAlmostEquals, -1, -1.11, 0.2 )
        lu.assertError( lu.assertNotAlmostEquals, -1, 1, nil )
        lu.assertError( lu.assertNotAlmostEquals, -1, nil, 0 )
        lu.assertError( lu.assertNotAlmostEquals, 1, 1.1, 0 )
        lu.assertError( lu.assertNotAlmostEquals, 1, 1.1, -0.1 )
    end

    function TestLuaUnitAssertions:test_assertNotEqualsDifferentTypes2()
        lu.assertNotEquals( 2, "abc" )
    end

    function TestLuaUnitAssertions:test_assertTrue()
        lu.assertTrue(true)
        lu.assertError( lu.assertTrue, false)
        lu.assertTrue(0)
        lu.assertTrue(1)
        lu.assertTrue("")
        lu.assertTrue("abc")
        lu.assertError( lu.assertTrue, nil )
        lu.assertTrue( function() return true end )
        lu.assertTrue( {} )
        lu.assertTrue( { 1 } )
    end

    function TestLuaUnitAssertions:test_assertFalse()
        lu.assertFalse(false)
        lu.assertError( lu.assertFalse, true)
        lu.assertFalse( nil )
        lu.assertError( lu.assertFalse, 0 )
        lu.assertError( lu.assertFalse, 1 )
        lu.assertError( lu.assertFalse, "" )
        lu.assertError( lu.assertFalse, "abc" )
        lu.assertError( lu.assertFalse, function() return true end )
        lu.assertError( lu.assertFalse, {} )
        lu.assertError( lu.assertFalse, { 1 } )
    end

    function TestLuaUnitAssertions:test_assertNil()
        lu.assertNil(nil)
        lu.assertError( lu.assertTrue, false)
        lu.assertError( lu.assertNil, 0)
        lu.assertError( lu.assertNil, "")
        lu.assertError( lu.assertNil, "abc")
        lu.assertError( lu.assertNil,  function() return true end )
        lu.assertError( lu.assertNil,  {} )
        lu.assertError( lu.assertNil,  { 1 } )
    end

    function TestLuaUnitAssertions:test_assertNotNil()
        lu.assertError( lu.assertNotNil, nil)
        lu.assertNotNil( false )
        lu.assertNotNil( 0 )
        lu.assertNotNil( "" )
        lu.assertNotNil( "abc" )
        lu.assertNotNil( function() return true end )
        lu.assertNotNil( {} )
        lu.assertNotNil( { 1 } )
    end

    function TestLuaUnitAssertions:test_assertStrContains()
        lu.assertStrContains( 'abcdef', 'abc' )
        lu.assertStrContains( 'abcdef', 'bcd' )
        lu.assertStrContains( 'abcdef', 'abcdef' )
        lu.assertStrContains( 'abc0', 0 )
        lu.assertError( lu.assertStrContains, 'ABCDEF', 'abc' )
        lu.assertError( lu.assertStrContains, '', 'abc' )
        lu.assertStrContains( 'abcdef', '' )
        lu.assertError( lu.assertStrContains, 'abcdef', 'abcx' )
        lu.assertError( lu.assertStrContains, 'abcdef', 'abcdefg' )
        lu.assertError( lu.assertStrContains, 'abcdef', 0 ) 
        lu.assertError( lu.assertStrContains, 'abcdef', {} ) 
        lu.assertError( lu.assertStrContains, 'abcdef', nil ) 

        lu.assertStrContains( 'abcdef', 'abc', false )
        lu.assertStrContains( 'abcdef', 'abc', true )
        lu.assertStrContains( 'abcdef', 'a.c', true )

        lu.assertError( lu.assertStrContains, 'abcdef', '.abc', true )
    end

    function TestLuaUnitAssertions:test_assertStrIContains()
        lu.assertStrIContains( 'ABcdEF', 'aBc' )
        lu.assertStrIContains( 'abCDef', 'bcd' )
        lu.assertStrIContains( 'abcdef', 'abcDef' )
        lu.assertError( lu.assertStrIContains, '', 'aBc' )
        lu.assertStrIContains( 'abcDef', '' )
        lu.assertError( lu.assertStrIContains, 'abcdef', 'abcx' )
        lu.assertError( lu.assertStrIContains, 'abcdef', 'abcdefg' )
    end

    function TestLuaUnitAssertions:test_assertNotStrContains()
        lu.assertError( lu.assertNotStrContains, 'abcdef', 'abc' )
        lu.assertError( lu.assertNotStrContains, 'abcdef', 'bcd' )
        lu.assertError( lu.assertNotStrContains, 'abcdef', 'abcdef' )
        lu.assertNotStrContains( '', 'abc' )
        lu.assertError( lu.assertNotStrContains, 'abcdef', '' )
        lu.assertError( lu.assertNotStrContains, 'abc0', 0 )
        lu.assertNotStrContains( 'abcdef', 'abcx' )
        lu.assertNotStrContains( 'abcdef', 'abcdefg' )
        lu.assertError( lu.assertNotStrContains, 'abcdef', {} ) 
        lu.assertError( lu.assertNotStrContains, 'abcdef', nil ) 

        lu.assertError( lu.assertNotStrContains, 'abcdef', 'abc', false )
        lu.assertError( lu.assertNotStrContains, 'abcdef', 'a.c', true )
        lu.assertNotStrContains( 'abcdef', 'a.cx', true )
    end

    function TestLuaUnitAssertions:test_assertNotStrIContains()
        lu.assertError( lu.assertNotStrIContains, 'aBcdef', 'abc' )
        lu.assertError( lu.assertNotStrIContains, 'abcdef', 'aBc' )
        lu.assertError( lu.assertNotStrIContains, 'abcdef', 'bcd' )
        lu.assertError( lu.assertNotStrIContains, 'abcdef', 'abcdef' )
        lu.assertNotStrIContains( '', 'abc' )
        lu.assertError( lu.assertNotStrIContains, 'abcdef', '' )
        lu.assertError( lu.assertNotStrIContains, 'abc0', 0 )
        lu.assertNotStrIContains( 'abcdef', 'abcx' )
        lu.assertNotStrIContains( 'abcdef', 'abcdefg' )
        lu.assertError( lu.assertNotStrIContains, 'abcdef', {} ) 
        lu.assertError( lu.assertNotStrIContains, 'abcdef', nil ) 
    end

    function TestLuaUnitAssertions:test_assertStrMatches()
        lu.assertStrMatches( 'abcdef', 'abcdef' )
        lu.assertStrMatches( 'abcdef', '..cde.' )
        lu.assertError( lu.assertStrMatches, 'abcdef', '..def')
        lu.assertError( lu.assertStrMatches, 'abCDEf', '..cde.')
        lu.assertStrMatches( 'abcdef', 'bcdef', 2 )
        lu.assertStrMatches( 'abcdef', 'bcde', 2, 5 )
        lu.assertStrMatches( 'abcdef', 'b..e', 2, 5 )
        lu.assertStrMatches( 'abcdef', 'ab..e', nil, 5 )
        lu.assertError( lu.assertStrMatches, 'abcdef', '' )
        lu.assertError( lu.assertStrMatches, '', 'abcdef' )

        lu.assertError( lu.assertStrMatches, 'abcdef', 0 ) 
        lu.assertError( lu.assertStrMatches, 'abcdef', {} ) 
        lu.assertError( lu.assertStrMatches, 'abcdef', nil ) 
    end

    function TestLuaUnitAssertions:test_assertItemsEquals()
        lu.assertItemsEquals(nil, nil)
        lu.assertItemsEquals({},{})
        lu.assertItemsEquals({1,2,3}, {3,1,2})
        lu.assertItemsEquals({nil},{nil})
        lu.assertItemsEquals({one=1,two=2,three=3}, {two=2,one=1,three=3})
        lu.assertItemsEquals({one=1,two=2,three=3}, {a=1,b=2,c=3})
        lu.assertItemsEquals({1,2,three=3}, {3,1,two=2})

        lu.assertError(assertItemsEquals, {1}, {})
        lu.assertError(assertItemsEquals, nil, {1,2,3})
        lu.assertError(assertItemsEquals, {1,2,3}, nil)
        lu.assertError(assertItemsEquals, {1,2,3,4}, {3,1,2})
        lu.assertError(assertItemsEquals, {1,2,3}, {3,1,2,4})
        lu.assertError(assertItemsEquals, {one=1,two=2,three=3,four=4}, {a=1,b=2,c=3})
        lu.assertError(assertItemsEquals, {one=1,two=2,three=3}, {a=1,b=2,c=3,d=4})
        lu.assertError(assertItemsEquals, {1,2,three=3}, {3,4,a=1,b=2})
        lu.assertError(assertItemsEquals, {1,2,three=3,four=4}, {3,a=1,b=2})

        lu.assertItemsEquals({one=1,two={1,2},three=3}, {one={1,2},two=1,three=3})
        lu.assertItemsEquals({one=1,
                           two={1,{3,2,one=1}},
                           three=3}, 
                        {two={1,{3,2,one=1}},
                         one=1,
                         three=3})
        -- itemsEquals is not recursive:
        lu.assertError( lu.assertItemsEquals,{1,{2,1},3}, {3,1,{1,2}})
        lu.assertError( lu.assertItemsEquals,{one=1,two={1,2},three=3}, {one={2,1},two=1,three=3})
        lu.assertError( lu.assertItemsEquals,{one=1,two={1,{3,2,one=1}},three=3}, {two={{3,one=1,2},1},one=1,three=3})
        lu.assertError( lu.assertItemsEquals,{one=1,two={1,{3,2,one=1}},three=3}, {two={{3,2,one=1},1},one=1,three=3})

        lu.assertError(assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1,three=2})
        lu.assertError(assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1,four=4})
        lu.assertError(assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1,'three'})
        lu.assertError(assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1,nil})
        lu.assertError(assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1})
    end

    function TestLuaUnitAssertions:test_assertIsNumber()
        lu.assertIsNumber(1)
        lu.assertIsNumber(1.4)
        lu.assertError(assertIsNumber, "hi there!")
        lu.assertError(assertIsNumber, nil)
        lu.assertError(assertIsNumber, {})
        lu.assertError(assertIsNumber, {1,2,3})
        lu.assertError(assertIsNumber, {1})
        lu.assertError(assertIsNumber, coroutine.create( function(v) local y=v+1 end ) )
        lu.assertError(assertIsTable, true)
    end

    function TestLuaUnitAssertions:test_assertIsString()
        lu.assertError(assertIsString, 1)
        lu.assertError(assertIsString, 1.4)
        lu.assertIsString("hi there!")
        lu.assertError(assertIsString, nil)
        lu.assertError(assertIsString, {})
        lu.assertError(assertIsString, {1,2,3})
        lu.assertError(assertIsString, {1})
        lu.assertError(assertIsString, coroutine.create( function(v) local y=v+1 end ) )
        lu.assertError(assertIsTable, true)
    end

    function TestLuaUnitAssertions:test_assertIsTable()
        lu.assertError(assertIsTable, 1)
        lu.assertError(assertIsTable, 1.4)
        lu.assertError(assertIsTable, "hi there!")
        lu.assertError(assertIsTable, nil)
        lu.assertIsTable({})
        lu.assertIsTable({1,2,3})
        lu.assertIsTable({1})
        lu.assertError(assertIsTable, true)
        lu.assertError(assertIsTable, coroutine.create( function(v) local y=v+1 end ) )
    end

    function TestLuaUnitAssertions:test_assertIsBoolean()
        lu.assertError(assertIsBoolean, 1)
        lu.assertError(assertIsBoolean, 1.4)
        lu.assertError(assertIsBoolean, "hi there!")
        lu.assertError(assertIsBoolean, nil)
        lu.assertError(assertIsBoolean, {})
        lu.assertError(assertIsBoolean, {1,2,3})
        lu.assertError(assertIsBoolean, {1})
        lu.assertError(assertIsBoolean, coroutine.create( function(v) local y=v+1 end ) )
        lu.assertIsBoolean(true)
        lu.assertIsBoolean(false)
    end

    function TestLuaUnitAssertions:test_assertIsNil()
        lu.assertError(assertIsNil, 1)
        lu.assertError(assertIsNil, 1.4)
        lu.assertError(assertIsNil, "hi there!")
        lu.assertIsNil(nil)
        lu.assertError(assertIsNil, {})
        lu.assertError(assertIsNil, {1,2,3})
        lu.assertError(assertIsNil, {1})
        lu.assertError(assertIsNil, false)
        lu.assertError(assertIsNil, coroutine.create( function(v) local y=v+1 end ) )
    end

    function TestLuaUnitAssertions:test_assertIsFunction()
        f = function() return true end

        lu.assertError(assertIsFunction, 1)
        lu.assertError(assertIsFunction, 1.4)
        lu.assertError(assertIsFunction, "hi there!")
        lu.assertError(assertIsFunction, nil)
        lu.assertError(assertIsFunction, {})
        lu.assertError(assertIsFunction, {1,2,3})
        lu.assertError(assertIsFunction, {1})
        lu.assertError(assertIsFunction, false)
        lu.assertError(assertIsFunction, coroutine.create( function(v) local y=v+1 end ) )
        lu.assertIsFunction(f)
    end

    function TestLuaUnitAssertions:test_assertIsCoroutine()
        lu.assertError(assertIsCoroutine, 1)
        lu.assertError(assertIsCoroutine, 1.4)
        lu.assertError(assertIsCoroutine, "hi there!")
        lu.assertError(assertIsCoroutine, nil)
        lu.assertError(assertIsCoroutine, {})
        lu.assertError(assertIsCoroutine, {1,2,3})
        lu.assertError(assertIsCoroutine, {1})
        lu.assertError(assertIsCoroutine, false)
        lu.assertError(assertIsCoroutine, function(v) local y=v+1 end )
        lu.assertIsCoroutine(coroutine.create( function(v) local y=v+1 end ) )
    end

    function TestLuaUnitAssertions:test_assertIsUserdata()
        lu.assertError(assertIsUserdata, 1)
        lu.assertError(assertIsUserdata, 1.4)
        lu.assertError(assertIsUserdata, "hi there!")
        lu.assertError(assertIsUserdata, nil)
        lu.assertError(assertIsUserdata, {})
        lu.assertError(assertIsUserdata, {1,2,3})
        lu.assertError(assertIsUserdata, {1})
        lu.assertError(assertIsUserdata, false)
        lu.assertError(assertIsUserdata, function(v) local y=v+1 end )
        lu.assertError(assertIsUserdata, coroutine.create( function(v) local y=v+1 end ) )
    end

    function TestLuaUnitAssertions:test_assertIs()
        local f = function() return true end
        local g = function() return true end
        local t1= {}
        local t2={1,2}
        local t3={1,2}
        local t4= {a=1,{1,2},day="today"}
        local s1='toto'
        local s2='toto'
        local s3='to'..'to'

        lu.assertIs(1,1)
        lu.assertIs(f,f)
        lu.assertIs('toto', 'toto')
        lu.assertIs(s1, s2)
        lu.assertIs(s1, s3)
        lu.assertIs(t1,t1)
        lu.assertIs(t4,t4)

        lu.assertError(assertIs, 1, 2)
        lu.assertError(assertIs, 1.4, 1)
        lu.assertError(assertIs, "hi there!", "hola")
        lu.assertError(assertIs, nil, 1)
        lu.assertError(assertIs, {}, {})
        lu.assertError(assertIs, {1,2,3}, f)
        lu.assertError(assertIs, f, g)
        lu.assertError(assertIs, t2,t3 )
    end

    function TestLuaUnitAssertions:test_assertNotIs()
        local f = function() return true end
        local g = function() return true end
        local t1= {}
        local t2={1,2}
        local t3={1,2}
        local t4= {a=1,{1,2},day="today"}
        local s1='toto'
        local s2='toto'

        lu.assertError( lu.assertNotIs, 1,1 )
        lu.assertError( lu.assertNotIs, f,f )
        lu.assertError( lu.assertNotIs, t1,t1 )
        lu.assertError( lu.assertNotIs, t4,t4)
        lu.assertError( lu.assertNotIs, s1,s2 )
        lu.assertError( lu.assertNotIs, 'toto', 'toto' )

        lu.assertNotIs(1, 2)
        lu.assertNotIs(1.4, 1)
        lu.assertNotIs("hi there!", "hola")
        lu.assertNotIs(nil, 1)
        lu.assertNotIs({}, {})
        lu.assertNotIs({1,2,3}, f)
        lu.assertNotIs(f, g)
        lu.assertNotIs(t2,t3)
    end

    function TestLuaUnitAssertions:test_assertTableNum()
        lu.assertEquals( 3, 3 )
        lu.assertNotEquals( 3, 4 )
        lu.assertEquals( {3}, {3} )
        lu.assertNotEquals( {3}, 3 )
        lu.assertNotEquals( {3}, {4} )
        lu.assertEquals( {x=1}, {x=1} )
        lu.assertNotEquals( {x=1}, {x=2} )
        lu.assertNotEquals( {x=1}, {y=1} )
    end
    function TestLuaUnitAssertions:test_assertTableStr()
        lu.assertEquals( '3', '3' )
        lu.assertNotEquals( '3', '4' )
        lu.assertEquals( {'3'}, {'3'} )
        lu.assertNotEquals( {'3'}, '3' )
        lu.assertNotEquals( {'3'}, {'4'} )
        lu.assertEquals( {x='1'}, {x='1'} )
        lu.assertNotEquals( {x='1'}, {x='2'} )
        lu.assertNotEquals( {x='1'}, {y='1'} )
    end
    function TestLuaUnitAssertions:test_assertTableLev2()
        lu.assertEquals( {x={'a'}}, {x={'a'}} )
        lu.assertNotEquals( {x={'a'}}, {x={'b'}} )
        lu.assertNotEquals( {x={'a'}}, {z={'a'}} )
        lu.assertEquals( {{x=1}}, {{x=1}} )
        lu.assertNotEquals( {{x=1}}, {{y=1}} )
        lu.assertEquals( {{x='a'}}, {{x='a'}} )
        lu.assertNotEquals( {{x='a'}}, {{x='b'}} )
    end
    function TestLuaUnitAssertions:test_assertTableList()
        lu.assertEquals( {3,4,5}, {3,4,5} )
        lu.assertNotEquals( {3,4,5}, {3,4,6} )
        lu.assertNotEquals( {3,4,5}, {3,5,4} )
        lu.assertEquals( {3,4,x=5}, {3,4,x=5} )
        lu.assertNotEquals( {3,4,x=5}, {3,4,x=6} )
        lu.assertNotEquals( {3,4,x=5}, {3,x=4,5} )
        lu.assertNotEquals( {3,4,5}, {2,3,4,5} )
        lu.assertNotEquals( {3,4,5}, {3,2,4,5} )
        lu.assertNotEquals( {3,4,5}, {3,4,5,6} )
    end

    function TestLuaUnitAssertions:test_assertTableNil()
        lu.assertEquals( {3,4,5}, {3,4,5} )
        lu.assertNotEquals( {3,4,5}, {nil,3,4,5} )
        lu.assertNotEquals( {3,4,5}, {nil,4,5} )
        lu.assertEquals( {3,4,5}, {3,4,5,nil} ) -- lua quirk
        lu.assertNotEquals( {3,4,5}, {3,4,nil} )
        lu.assertNotEquals( {3,4,5}, {3,nil,5} )
        lu.assertNotEquals( {3,4,5}, {3,4,nil,5} )
    end
    
    function TestLuaUnitAssertions:test_assertTableNilFront()
        lu.assertEquals( {nil,4,5}, {nil,4,5} )
        lu.assertNotEquals( {nil,4,5}, {nil,44,55} )
        lu.assertEquals( {nil,'4','5'}, {nil,'4','5'} )
        lu.assertNotEquals( {nil,'4','5'}, {nil,'44','55'} )
        lu.assertEquals( {nil,{4,5}}, {nil,{4,5}} )
        lu.assertNotEquals( {nil,{4,5}}, {nil,{44,55}} )
        lu.assertNotEquals( {nil,{4}}, {nil,{44}} )
        lu.assertEquals( {nil,{x=4,5}}, {nil,{x=4,5}} )
        lu.assertEquals( {nil,{x=4,5}}, {nil,{5,x=4}} ) -- lua quirk
        lu.assertEquals( {nil,{x=4,y=5}}, {nil,{y=5,x=4}} ) -- lua quirk
        lu.assertNotEquals( {nil,{x=4,5}}, {nil,{y=4,5}} )
    end

    function TestLuaUnitAssertions:test_assertTableAdditions()
        lu.assertEquals( {1,2,3}, {1,2,3} )
        lu.assertNotEquals( {1,2,3}, {1,2,3,4} )
        lu.assertNotEquals( {1,2,3,4}, {1,2,3} )
        lu.assertEquals( {1,x=2,3}, {1,x=2,3} )
        lu.assertNotEquals( {1,x=2,3}, {1,x=2,3,y=4} )
        lu.assertNotEquals( {1,x=2,3,y=4}, {1,x=2,3} )
    end


TestLuaUnitAssertionsError = {}

    function TestLuaUnitAssertionsError:setUp()
        self.f = function ( v )
            local y = v + 1
        end
        self.f_with_error = function (v)
            local y = v + 2
            error('This is an error', 2)
        end
    end

    function TestLuaUnitAssertionsError:test_assertError()
        local x = 1

        -- f_with_error generates an error
        has_error = not pcall( self.f_with_error, x )
        lu.assertEquals( has_error, true )

        -- f does not generate an error
        has_error = not pcall( self.f, x )
        lu.assertEquals( has_error, false )

        -- lu.assertError is happy with f_with_error
        lu.assertError( self.f_with_error, x )

        -- lu.assertError is unhappy with f
        has_error = not pcall( lu.assertError, self.f, x )
        lu.assertError( has_error, true )

        -- multiple arguments
        local function f_with_multi_arguments(a,b,c)
            if a == b and b == c then return end
            error("three arguments not equal")
        end

        lu.assertError( f_with_multi_arguments, 1, 1, 3 )
        lu.assertError( f_with_multi_arguments, 1, 3, 1 )
        lu.assertError( f_with_multi_arguments, 3, 1, 1 )

        has_error = not pcall( lu.assertError, f_with_multi_arguments, 1, 1, 1 )
        lu.assertEquals( has_error, true )
    end

    function TestLuaUnitAssertionsError:test_assertErrorMsgContains()
        local x = 1
        lu.assertError( lu.assertErrorMsgContains, 'toto', self.f, x )
        lu.assertErrorMsgContains( 'is an err', self.f_with_error, x )
        lu.assertErrorMsgContains( 'This is an error', self.f_with_error, x )
        lu.assertError( lu.assertErrorMsgContains, ' This is an error', self.f_with_error, x )
        lu.assertError( lu.assertErrorMsgContains, 'This .. an error', self.f_with_error, x )
    end

    function TestLuaUnitAssertionsError:test_assertErrorMsgEquals()
        local x = 1
        lu.assertError( lu.assertErrorMsgEquals, 'toto', self.f, x )
        lu.assertError( lu.assertErrorMsgEquals, 'is an err', self.f_with_error, x )
        lu.assertErrorMsgEquals( 'This is an error', self.f_with_error, x )
        lu.assertError( lu.assertErrorMsgEquals, ' This is an error', self.f_with_error, x )
        lu.assertError( lu.assertErrorMsgEquals, 'This .. an error', self.f_with_error, x )
    end

    function TestLuaUnitAssertionsError:test_assertErrorMsgMatches()
        local x = 1
        lu.assertError( lu.assertErrorMsgMatches, 'toto', self.f, x )
        lu.assertError( lu.assertErrorMsgMatches, 'is an err', self.f_with_error, x )
        lu.assertErrorMsgMatches( 'This is an error', self.f_with_error, x )
        lu.assertErrorMsgMatches( 'This is .. error', self.f_with_error, x )
        lu.assertError( lu.assertErrorMsgMatches, ' This is an error', self.f_with_error, x )
    end

------------------------------------------------------------------
--
--                       Error message tests
--
------------------------------------------------------------------

TestLuaUnitErrorMsg = {} --class
    TestLuaUnitErrorMsg.__class__ = 'TestLuaUnitErrorMsg'

    function TestLuaUnitErrorMsg:setUp()
        self.old_ORDER_ACTUAL_EXPECTED = lu.ORDER_ACTUAL_EXPECTED
        self.old_PRINT_TABLE_REF_IN_ERROR_MSG = lu.PRINT_TABLE_REF_IN_ERROR_MSG
    end

    function TestLuaUnitErrorMsg:tearDown()
        lu.ORDER_ACTUAL_EXPECTED = self.old_ORDER_ACTUAL_EXPECTED
        lu.PRINT_TABLE_REF_IN_ERROR_MSG = self.old_PRINT_TABLE_REF_IN_ERROR_MSG
    end

    function TestLuaUnitErrorMsg:test_assertEqualsMsg()
        lu.assertErrorMsgEquals( 'expected: 2, actual: 1', lu.assertEquals, 1, 2  )
        lu.assertErrorMsgEquals( 'expected: "exp"\nactual: "act"', lu.assertEquals, 'act', 'exp' )
        lu.assertErrorMsgEquals( 'expected: \n"exp\npxe"\nactual: \n"act\ntca"', lu.assertEquals, 'act\ntca', 'exp\npxe' )
        lu.assertErrorMsgEquals( 'expected: true, actual: false', lu.assertEquals, false, true )
        if _VERSION == 'Lua 5.3' then
            lu.assertErrorMsgEquals( 'expected: 1.2, actual: 1.0', lu.assertEquals, 1.0, 1.2)
        else
            lu.assertErrorMsgEquals( 'expected: 1.2, actual: 1', lu.assertEquals, 1.0, 1.2)
        end
        lu.assertErrorMsgMatches( 'expected: {1, 2, 3}\nactual: {3, 2, 1}', lu.assertEquals, {3,2,1}, {1,2,3} )
        lu.assertErrorMsgMatches( 'expected: {one=1, two=2}\nactual: {3, 2, 1}', lu.assertEquals, {3,2,1}, {one=1,two=2} )
        lu.assertErrorMsgEquals( 'expected: 2, actual: nil', lu.assertEquals, nil, 2 )
    end 

    function TestLuaUnitErrorMsg:test_assertEqualsOrderReversedMsg()
        lu.ORDER_ACTUAL_EXPECTED = false
        lu.assertErrorMsgEquals( 'expected: 1, actual: 2', lu.assertEquals, 1, 2  )
        lu.assertErrorMsgEquals( 'expected: "act"\nactual: "exp"', lu.assertEquals, 'act', 'exp' )
    end 

    function TestLuaUnitErrorMsg:test_assertAlmostEqualsMsg()
        lu.assertErrorMsgEquals('Values are not almost equal\nExpected: 1 with margin of 0.1, received: 2', lu.assertAlmostEquals, 2, 1, 0.1 )
    end

    function TestLuaUnitErrorMsg:test_assertAlmostEqualsOrderReversedMsg()
        lu.ORDER_ACTUAL_EXPECTED = false
        lu.assertErrorMsgEquals('Values are not almost equal\nExpected: 2 with margin of 0.1, received: 1', lu.assertAlmostEquals, 2, 1, 0.1 )
    end

    function TestLuaUnitErrorMsg:test_assertNotAlmostEqualsMsg()
        lu.assertErrorMsgEquals('Values are almost equal\nExpected: 1 with a difference above margin of 0.2, received: 1.1', lu.assertNotAlmostEquals, 1.1, 1, 0.2 )
    end

    function TestLuaUnitErrorMsg:test_assertNotAlmostEqualsMsg()
        lu.ORDER_ACTUAL_EXPECTED = false
        lu.assertErrorMsgEquals('Values are almost equal\nExpected: 1.1 with a difference above margin of 0.2, received: 1', lu.assertNotAlmostEquals, 1.1, 1, 0.2 )
    end

    function TestLuaUnitErrorMsg:test_assertNotEqualsMsg()
        lu.assertErrorMsgEquals( 'Received the not expected value: 1', lu.assertNotEquals, 1, 1  )
        lu.assertErrorMsgMatches( 'Received the not expected value: {1, 2}', lu.assertNotEquals, {1,2}, {1,2} )
        lu.assertErrorMsgEquals( 'Received the not expected value: nil', lu.assertNotEquals, nil, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertNotEqualsOrderReversedMsg()
        lu.ORDER_ACTUAL_EXPECTED = false
        lu.assertErrorMsgEquals( 'Received the not expected value: 1', lu.assertNotEquals, 1, 1  )
    end 

    function TestLuaUnitErrorMsg:test_assertTrueFalse()
        lu.assertErrorMsgEquals( 'expected: true, actual: false', lu.assertTrue, false )
        lu.assertErrorMsgEquals( 'expected: true, actual: nil', lu.assertTrue, nil )
        lu.assertErrorMsgEquals( 'expected: false, actual: true', lu.assertFalse, true )
        lu.assertErrorMsgEquals( 'expected: false, actual: 0', lu.assertFalse, 0)
        lu.assertErrorMsgMatches( 'expected: false, actual: {}', lu.assertFalse, {})
        lu.assertErrorMsgEquals( 'expected: false, actual: "abc"', lu.assertFalse, 'abc')
        lu.assertErrorMsgContains( 'expected: false, actual: function', lu.assertFalse, function () end )
    end 

    function TestLuaUnitErrorMsg:test_assertNil()
        lu.assertErrorMsgEquals( 'expected: nil, actual: false', lu.assertNil, false )
        lu.assertErrorMsgEquals( 'expected non nil value, received nil', lu.assertNotNil, nil )
    end

    function TestLuaUnitErrorMsg:test_assertStrContains()
        lu.assertErrorMsgEquals( 'Error, substring "xxx" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'xxx' )
        lu.assertErrorMsgEquals( 'Error, substring "aBc" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'aBc' )
        lu.assertErrorMsgEquals( 'Error, substring "xxx" was not found in string ""', lu.assertStrContains, '', 'xxx' )

        lu.assertErrorMsgEquals( 'Error, substring "xxx" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'xxx', false )
        lu.assertErrorMsgEquals( 'Error, substring "aBc" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'aBc', false )
        lu.assertErrorMsgEquals( 'Error, substring "xxx" was not found in string ""', lu.assertStrContains, '', 'xxx', false )

        lu.assertErrorMsgEquals( 'Error, regexp "xxx" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'xxx', true )
        lu.assertErrorMsgEquals( 'Error, regexp "aBc" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'aBc', true )
        lu.assertErrorMsgEquals( 'Error, regexp "xxx" was not found in string ""', lu.assertStrContains, '', 'xxx', true )

    end 

    function TestLuaUnitErrorMsg:test_assertStrIContains()
        lu.assertErrorMsgEquals( 'Error, substring "xxx" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'xxx' )
        lu.assertErrorMsgEquals( 'Error, substring "xxx" was not found in string ""', lu.assertStrContains, '', 'xxx' )
    end 

    function TestLuaUnitErrorMsg:test_assertNotStrContains()
        lu.assertErrorMsgEquals( 'Error, substring "abc" was found in string "abcdef"', lu.assertNotStrContains, 'abcdef', 'abc' )
        lu.assertErrorMsgEquals( 'Error, substring "abc" was found in string "abcdef"', lu.assertNotStrContains, 'abcdef', 'abc', false )
        lu.assertErrorMsgEquals( 'Error, regexp "..." was found in string "abcdef"', lu.assertNotStrContains, 'abcdef', '...', true)
    end 

    function TestLuaUnitErrorMsg:test_assertNotStrIContains()
        lu.assertErrorMsgEquals( 'Error, substring "aBc" was found (case insensitively) in string "abcdef"', lu.assertNotStrIContains, 'abcdef', 'aBc' )
        lu.assertErrorMsgEquals( 'Error, substring "abc" was found (case insensitively) in string "abcdef"', lu.assertNotStrIContains, 'abcdef', 'abc' )
    end 

    function TestLuaUnitErrorMsg:test_assertStrMatches()
        lu.assertErrorMsgEquals('Error, pattern "xxx" was not matched by string "abcdef"', lu.assertStrMatches, 'abcdef', 'xxx' )
    end 

    function TestLuaUnitErrorMsg:test_assertIsNumber()
        lu.assertErrorMsgEquals( 'Expected: a number value, actual: type string, value "abc"', lu.assertIsNumber, 'abc' )
        lu.assertErrorMsgEquals( 'Expected: a number value, actual: type nil, value nil', lu.assertIsNumber, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertIsString()
        lu.assertErrorMsgEquals( 'Expected: a string value, actual: type number, value 1.2', lu.assertIsString, 1.2 )
        lu.assertErrorMsgEquals( 'Expected: a string value, actual: type nil, value nil', lu.assertIsString, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertIsTable()
        lu.assertErrorMsgEquals( 'Expected: a table value, actual: type number, value 1.2', lu.assertIsTable, 1.2 )
        lu.assertErrorMsgEquals( 'Expected: a table value, actual: type nil, value nil', lu.assertIsTable, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertIsBoolean()
        lu.assertErrorMsgEquals( 'Expected: a boolean value, actual: type number, value 1.2', lu.assertIsBoolean, 1.2 )
        lu.assertErrorMsgEquals( 'Expected: a boolean value, actual: type nil, value nil', lu.assertIsBoolean, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertIsFunction()
        lu.assertErrorMsgEquals( 'Expected: a function value, actual: type number, value 1.2', lu.assertIsFunction, 1.2 )
        lu.assertErrorMsgEquals( 'Expected: a function value, actual: type nil, value nil', lu.assertIsFunction, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertIsCoroutine()
        lu.assertErrorMsgEquals( 'Expected: a thread value, actual: type number, value 1.2', lu.assertIsCoroutine, 1.2 )
        lu.assertErrorMsgEquals( 'Expected: a thread value, actual: type nil, value nil', lu.assertIsCoroutine, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertIsUserdata()
        lu.assertErrorMsgEquals( 'Expected: a userdata value, actual: type number, value 1.2', lu.assertIsUserdata, 1.2 )
        lu.assertErrorMsgEquals( 'Expected: a userdata value, actual: type nil, value nil', lu.assertIsUserdata, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertIs()
        lu.assertErrorMsgEquals( 'Expected object and actual object are not the same\nExpected: 1, actual: 2', lu.assertIs, 2, 1 )
        lu.ORDER_ACTUAL_EXPECTED = false
        lu.assertErrorMsgEquals( 'Expected object and actual object are not the same\nExpected: 2, actual: 1', lu.assertIs, 2, 1 )
    end 

    function TestLuaUnitErrorMsg:test_assertNotIs()
        local v = {1,2}
        lu.assertErrorMsgMatches( 'Expected object and actual object are the same object: {1, 2}', lu.assertNotIs, v, v )
    end 

    function TestLuaUnitErrorMsg:test_assertItemsEquals()
        lu.assertErrorMsgMatches('Contents of the tables are not identical:\nExpected: {one=2, two=3}\nActual: {1, 2}' , lu.assertItemsEquals, {1,2}, {one=2, two=3} )
    end 

    function TestLuaUnitErrorMsg:test_assertError()
        lu.assertErrorMsgEquals('Expected an error when calling function but no error generated' , lu.assertError, function( v ) local y = v+1 end, 3 )
    end 

    function TestLuaUnitErrorMsg:test_assertErrorMsg()
        lu.assertErrorMsgEquals('No error generated when calling function but expected error: "bla bla bla"' , lu.assertErrorMsgEquals, 'bla bla bla', function( v ) local y = v+1 end, 3 )
        lu.assertErrorMsgEquals('No error generated when calling function but expected error containing: "bla bla bla"' , lu.assertErrorMsgContains, 'bla bla bla', function( v ) local y = v+1 end, 3 )
        lu.assertErrorMsgEquals('No error generated when calling function but expected error matching: "bla bla bla"' , lu.assertErrorMsgMatches, 'bla bla bla', function( v ) local y = v+1 end, 3 )

        lu.assertErrorMsgEquals('Exact error message expected: "bla bla bla"\nError message received: "toto xxx"\n' , lu.assertErrorMsgEquals, 'bla bla bla', function( v ) error('toto xxx',2) end, 3 )
        lu.assertErrorMsgEquals('Error message does not contain: "bla bla bla"\nError message received: "toto xxx"\n' , lu.assertErrorMsgContains, 'bla bla bla', function( v ) error('toto xxx',2) end, 3 )
        lu.assertErrorMsgEquals('Error message does not match: "bla bla bla"\nError message received: "toto xxx"\n' , lu.assertErrorMsgMatches, 'bla bla bla', function( v ) error('toto xxx',2) end, 3 )

    end 

    function TestLuaUnitErrorMsg:test_printTableWithRef()
        lu.PRINT_TABLE_REF_IN_ERROR_MSG = true
        lu.assertErrorMsgMatches( 'Received the not expected value: <table: 0?x?[%x]+> {1, 2}', lu.assertNotEquals, {1,2}, {1,2} )
        -- trigger multiline prettystr
        lu.assertErrorMsgMatches( 'Received the not expected value: <table: 0?x?[%x]+> {1, 2, 3, 4}', lu.assertNotEquals, {1,2,3,4}, {1,2,3,4} )
        lu.assertErrorMsgMatches( 'expected: false, actual: <table: 0?x?[%x]+> {}', lu.assertFalse, {})
        local v = {1,2}
        lu.assertErrorMsgMatches( 'Expected object and actual object are the same object: <table: 0?x?[%x]+> {1, 2}', lu.assertNotIs, v, v )
        lu.assertErrorMsgMatches('Contents of the tables are not identical:\nExpected: <table: 0?x?[%x]+> {one=2, two=3}\nActual: <table: 0?x?[%x]+> {1, 2}' , lu.assertItemsEquals, {1,2}, {one=2, two=3} )
        lu.assertErrorMsgMatches( 'expected: <table: 0?x?[%x]+> {1, 2, 3}\nactual: <table: 0?x?[%x]+> {3, 2, 1}', lu.assertEquals, {3,2,1}, {1,2,3} )
        -- trigger multiline prettystr
        lu.assertErrorMsgMatches( 'expected: <table: 0?x?[%x]+> {1, 2, 3, 4}\nactual: <table: 0?x?[%x]+> {3, 2, 1, 4}', lu.assertEquals, {3,2,1,4}, {1,2,3,4} )
        lu.assertErrorMsgMatches( 'expected: <table: 0?x?[%x]+> {one=1, two=2}\nactual: <table: 0?x?[%x]+> {3, 2, 1}', lu.assertEquals, {3,2,1}, {one=1,two=2} )
    end

------------------------------------------------------------------
--
--                       Execution Tests 
--
------------------------------------------------------------------


MyTestToto1 = {} --class
    function MyTestToto1:test1() table.insert( executedTests, "MyTestToto1:test1" ) end
    function MyTestToto1:testb() table.insert( executedTests, "MyTestToto1:testb" ) end
    function MyTestToto1:test3() table.insert( executedTests, "MyTestToto1:test3" ) end
    function MyTestToto1:testa() table.insert( executedTests, "MyTestToto1:testa" ) end
    function MyTestToto1:test2() table.insert( executedTests, "MyTestToto1:test2" ) end

MyTestToto2 = {} --class
    function MyTestToto2:test1() table.insert( executedTests, "MyTestToto2:test1" ) end

MyTestWithFailures = {} --class
    function MyTestWithFailures:testWithFailure1() lu.assertEquals(1, 2) end
    function MyTestWithFailures:testWithFailure2() lu.assertError( function() end ) end
    function MyTestWithFailures:testOk() end

MyTestOk = {} --class
    function MyTestOk:testOk1() end
    function MyTestOk:testOk2() end

function MyTestFunction()
    table.insert( executedTests, "MyTestFunction" ) 
end

TestLuaUnitExecution = {} --class

    TestLuaUnitExecution.__class__ = 'TestLuaUnitExecution'

    function TestLuaUnitExecution:tearDown()
        executedTests = {}
        lu.LuaUnit.isTestName = lu.LuaUnit.isTestNameOld
    end

    function TestLuaUnitExecution:setUp()
        executedTests = {}
        lu.LuaUnit.isTestNameOld = lu.LuaUnit.isTestName
        lu.LuaUnit.isTestName = function( s ) return (string.sub(s,1,6) == 'MyTest') end
    end

    function TestLuaUnitExecution:test_collectTests()
        allTests = lu.LuaUnit.collectTests()
        lu.assertEquals( allTests, {"MyTestFunction", "MyTestOk", "MyTestToto1", "MyTestToto2","MyTestWithFailures"})
    end

    function TestLuaUnitExecution:test_MethodsAreExecutedInRightOrder()
        local runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuite( 'MyTestToto1' )
        lu.assertEquals( #executedTests, 5 )
        lu.assertEquals( executedTests[1], "MyTestToto1:test1" )
        lu.assertEquals( executedTests[2], "MyTestToto1:test2" )
        lu.assertEquals( executedTests[3], "MyTestToto1:test3" )
        lu.assertEquals( executedTests[4], "MyTestToto1:testa" )
        lu.assertEquals( executedTests[5], "MyTestToto1:testb" )
    end

    function TestLuaUnitExecution:test_runSuiteByNames()
        -- note: this also test that names are executed in explicit order
        local runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByNames( { 'MyTestToto2', 'MyTestToto1', 'MyTestFunction' } )
        lu.assertEquals( #executedTests, 7 )
        lu.assertEquals( executedTests[1], "MyTestToto2:test1" )
        lu.assertEquals( executedTests[2], "MyTestToto1:test1" )
        lu.assertEquals( executedTests[7], "MyTestFunction" )
    end

    function TestLuaUnitExecution:testRunSomeTestByGlobalInstance( )
        lu.assertEquals( #executedTests, 0 )
        local runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'Toto', MyTestToto1 } }  )
        lu.assertEquals( #executedTests, 5 )

        lu.assertEquals( #runner.result.tests, 5 )
        lu.assertEquals( runner.result.tests[1].testName, "Toto.test1" )
        lu.assertEquals( runner.result.tests[5].testName, "Toto.testb" )
    end

    function TestLuaUnitExecution:testRunSomeTestByLocalInstance( )
        MyLocalTestToto1 = {} --class
        function MyLocalTestToto1:test1() table.insert( executedTests, "MyLocalTestToto1:test1" ) end
        MyLocalTestToto2 = {} --class
        function MyLocalTestToto2:test1() table.insert( executedTests, "MyLocalTestToto2:test1" ) end
        function MyLocalTestToto2:test2() table.insert( executedTests, "MyLocalTestToto2:test2" ) end
        function MyLocalTestFunction() table.insert( executedTests, "MyLocalTestFunction" ) end
 
        lu.assertEquals( #executedTests, 0 )
        local runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { 
            { 'MyLocalTestToto1', MyLocalTestToto1 },
            { 'MyLocalTestToto2.test2', MyLocalTestToto2 },
            { 'MyLocalTestFunction', MyLocalTestFunction },
        } )
        lu.assertEquals( #executedTests, 3 )
        lu.assertEquals( executedTests[1], 'MyLocalTestToto1:test1')
        lu.assertEquals( executedTests[2], 'MyLocalTestToto2:test2')
        lu.assertEquals( executedTests[3], 'MyLocalTestFunction')
    end

    function TestLuaUnitExecution:testRunReturnsNumberOfFailures()
        local runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        ret = runner:runSuite( 'MyTestWithFailures' )
        lu.assertEquals(ret, 2)

        ret = runner:runSuite( 'MyTestToto1' )
        lu.assertEquals(ret, 0)
    end

    function TestLuaUnitExecution:testTestCountAndFailCount()
        local runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuite( 'MyTestWithFailures' )
        lu.assertEquals( runner.result.testCount, 3)
        lu.assertEquals( runner.result.failureCount, 2)

        runner:runSuite( 'MyTestToto1' )
        lu.assertEquals( runner.result.testCount, 5)
        lu.assertEquals( runner.result.failureCount, 0)
    end

    function TestLuaUnitExecution:testRunSetupAndTeardown()
        local myExecutedTests = {}
        local MyTestWithSetupTeardown = {}
            function MyTestWithSetupTeardown:setUp()    table.insert( myExecutedTests, '1setUp' ) end
            function MyTestWithSetupTeardown:test1()    table.insert( myExecutedTests, '1test1' ) end
            function MyTestWithSetupTeardown:test2()    table.insert( myExecutedTests, '1test2' ) end
            function MyTestWithSetupTeardown:tearDown() table.insert( myExecutedTests, '1tearDown' )  end

        local MyTestWithSetupTeardown2 = {}
            function MyTestWithSetupTeardown2:setUp()    table.insert( myExecutedTests, '2setUp' ) end
            function MyTestWithSetupTeardown2:test1()    table.insert( myExecutedTests, '2test1' ) end
            function MyTestWithSetupTeardown2:tearDown() table.insert( myExecutedTests, '2tearDown' )  end

        local runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupTeardown.test1', MyTestWithSetupTeardown } } )
        lu.assertEquals( runner.result.failureCount, 0 )
        lu.assertEquals( myExecutedTests[1], '1setUp' )   
        lu.assertEquals( myExecutedTests[2], '1test1')
        lu.assertEquals( myExecutedTests[3], '1tearDown')
        lu.assertEquals( #myExecutedTests, 3)

        myExecutedTests = {}
        runner:runSuiteByInstances( { 
            { 'MyTestWithSetupTeardown', MyTestWithSetupTeardown },
            { 'MyTestWithSetupTeardown2', MyTestWithSetupTeardown2 } 
        } )
        lu.assertEquals( runner.result.failureCount, 0 )
        lu.assertEquals( myExecutedTests[1], '1setUp' )   
        lu.assertEquals( myExecutedTests[2], '1test1')
        lu.assertEquals( myExecutedTests[3], '1tearDown')
        lu.assertEquals( myExecutedTests[4], '1setUp' )   
        lu.assertEquals( myExecutedTests[5], '1test2')
        lu.assertEquals( myExecutedTests[6], '1tearDown')
        lu.assertEquals( myExecutedTests[7], '2setUp' )   
        lu.assertEquals( myExecutedTests[8], '2test1')
        lu.assertEquals( myExecutedTests[9], '2tearDown')
        lu.assertEquals( #myExecutedTests, 9)
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors1()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ); lu.assertEquals( 'b', 'c') end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' )  end

        local runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.failureCount, 1 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'tearDown')
        lu.assertEquals( #myExecutedTests, 2)
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors2()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ) end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ); lu.assertEquals( 'b', 'c')   end

        runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.failureCount, 1 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'test1' )   
        lu.assertEquals( myExecutedTests[3], 'tearDown')
        lu.assertEquals( #myExecutedTests, 3)
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors3()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ); lu.assertEquals( 'b', 'c') end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ); lu.assertEquals( 'b', 'c')   end

        runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.failureCount, 1 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'tearDown')
        lu.assertEquals( #myExecutedTests, 2)
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors4()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ); lu.assertEquals( 'b', 'c') end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ); lu.assertEquals( 'b', 'c')  end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ); lu.assertEquals( 'b', 'c')   end

        runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.failureCount, 1 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'tearDown')
        lu.assertEquals( #myExecutedTests, 2)
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors5()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ) end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ); lu.assertEquals( 'b', 'c')  end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ); lu.assertEquals( 'b', 'c')   end

        runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.failureCount, 1 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'test1' )   
        lu.assertEquals( myExecutedTests[3], 'tearDown')
        lu.assertEquals( #myExecutedTests, 3)
    end

    function TestLuaUnitExecution:testOutputInterface()
        local runner = lu.LuaUnit:new()
        runner.outputType = Mock
        runner:runSuite( 'MyTestWithFailures', 'MyTestOk' )
        m = runner.output

        lu.assertEquals( m.calls[1][1], 'startSuite' )
        lu.assertEquals(#m.calls[1], 2 )

        lu.assertEquals( m.calls[2][1], 'startClass' )
        lu.assertEquals( m.calls[2][3], 'MyTestWithFailures' )
        lu.assertEquals(#m.calls[2], 3 )

        lu.assertEquals( m.calls[3][1], 'startTest' )
        lu.assertEquals( m.calls[3][3], 'MyTestWithFailures.testOk' )
        lu.assertEquals(#m.calls[3], 3 )

        lu.assertEquals( m.calls[4][1], 'endTest' )
        lu.assertEquals( m.calls[4][3], false )
        lu.assertEquals(#m.calls[4], 3 )

        lu.assertEquals( m.calls[5][1], 'startTest' )
        lu.assertEquals( m.calls[5][3], 'MyTestWithFailures.testWithFailure1' )
        lu.assertEquals(#m.calls[5], 3 )

        lu.assertEquals( m.calls[6][1], 'addFailure' )
        lu.assertEquals(#m.calls[6], 4 )

        lu.assertEquals( m.calls[7][1], 'endTest' )
        lu.assertEquals( m.calls[7][3], true )
        lu.assertEquals(#m.calls[7], 3 )


        lu.assertEquals( m.calls[8][1], 'startTest' )
        lu.assertEquals( m.calls[8][3], 'MyTestWithFailures.testWithFailure2' )
        lu.assertEquals(#m.calls[8], 3 )

        lu.assertEquals( m.calls[9][1], 'addFailure' )
        lu.assertEquals(#m.calls[9], 4 )

        lu.assertEquals( m.calls[10][1], 'endTest' )
        lu.assertEquals( m.calls[10][3], true )
        lu.assertEquals(#m.calls[10], 3 )

        lu.assertEquals( m.calls[11][1], 'endClass' )
        lu.assertEquals(#m.calls[11], 2 )

        lu.assertEquals( m.calls[12][1], 'startClass' )
        lu.assertEquals( m.calls[12][3], 'MyTestOk' )
        lu.assertEquals(#m.calls[12], 3 )

        lu.assertEquals( m.calls[13][1], 'startTest' )
        lu.assertEquals( m.calls[13][3], 'MyTestOk.testOk1' )
        lu.assertEquals(#m.calls[13], 3 )

        lu.assertEquals( m.calls[14][1], 'endTest' )
        lu.assertEquals( m.calls[14][3], false )
        lu.assertEquals(#m.calls[14], 3 )

        lu.assertEquals( m.calls[15][1], 'startTest' )
        lu.assertEquals( m.calls[15][3], 'MyTestOk.testOk2' )
        lu.assertEquals(#m.calls[15], 3 )

        lu.assertEquals( m.calls[16][1], 'endTest' )
        lu.assertEquals( m.calls[16][3], false )
        lu.assertEquals(#m.calls[16], 3 )

        lu.assertEquals( m.calls[17][1], 'endClass' )
        lu.assertEquals(#m.calls[17], 2 )

        lu.assertEquals( m.calls[18][1], 'endSuite' )
        lu.assertEquals(#m.calls[18], 2 )

        lu.assertEquals( m.calls[19], nil )

    end

    function TestLuaUnitExecution:test_filterWithPattern()

        runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuite('-p', 'Function', '-p', 'Toto.' )
        lu.assertEquals( executedTests[1], "MyTestFunction" )
        lu.assertEquals( executedTests[2], "MyTestToto1:test1" )
        lu.assertEquals( executedTests[3], "MyTestToto1:test2" )
        lu.assertEquals( executedTests[4], "MyTestToto1:test3" )
        lu.assertEquals( executedTests[5], "MyTestToto1:testa" )
        lu.assertEquals( executedTests[6], "MyTestToto1:testb" )
        lu.assertEquals( executedTests[7], "MyTestToto2:test1" )
        lu.assertEquals( #executedTests, 7)
    end

------------------------------------------------------------------
--
--                      Results Tests              
--
------------------------------------------------------------------

TestLuaUnitResults = {} -- class

    TestLuaUnitResults.__class__ = 'TestLuaUnitResults'

    function TestLuaUnitResults:tearDown()
        executedTests = {}
        lu.LuaUnit.isTestName = lu.LuaUnit.isTestNameOld
    end

    function TestLuaUnitResults:setUp()
        executedTests = {}
        lu.LuaUnit.isTestNameOld = lu.LuaUnit.isTestName
        lu.LuaUnit.isTestName = function( s ) return (string.sub(s,1,6) == 'MyTest') end
    end

    function TestLuaUnitResults:test_nodeStatus()
        es = lu.NodeStatus:new()
        lu.assertEquals( es.status, lu.NodeStatus.PASS )
        lu.assertNil( es.msg )
        lu.assertNil( es.stackTrace )

        es:fail( 'msgToto', 'stackTraceToto' )
        lu.assertEquals( es.status, lu.NodeStatus.FAIL )
        lu.assertEquals( es.msg, 'msgToto' )
        lu.assertEquals( es.stackTrace, 'stackTraceToto' )

        es2 = lu.NodeStatus:new()
        lu.assertEquals( es2.status, lu.NodeStatus.PASS )
        lu.assertNil( es2.msg )
        lu.assertNil( es2.stackTrace )

        es:pass()
        lu.assertEquals( es.status, lu.NodeStatus.PASS )
        lu.assertNil( es.msg )
        lu.assertNil( es.stackTrace )

    end

    function TestLuaUnitResults:test_runSuiteOk()
        local runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByNames( { 'MyTestToto2', 'MyTestToto1', 'MyTestFunction' } )
        lu.assertEquals( #runner.result.tests, 7 )
        lu.assertEquals( #runner.result.failures, 0 )

        lu.assertEquals( runner.result.tests[1].testName,"MyTestToto2.test1" )
        lu.assertEquals( runner.result.tests[1].number, 1 )
        lu.assertEquals( runner.result.tests[1].className, 'MyTestToto2' )
        lu.assertEquals( runner.result.tests[1].status, lu.NodeStatus.PASS )

        lu.assertEquals( runner.result.tests[2].testName,"MyTestToto1.test1" )
        lu.assertEquals( runner.result.tests[2].number, 2 )
        lu.assertEquals( runner.result.tests[2].className, 'MyTestToto1' )
        lu.assertEquals( runner.result.tests[2].status, lu.NodeStatus.PASS )

        lu.assertEquals( runner.result.tests[3].testName,"MyTestToto1.test2" )
        lu.assertEquals( runner.result.tests[3].number, 3 )
        lu.assertEquals( runner.result.tests[3].className, 'MyTestToto1' )
        lu.assertEquals( runner.result.tests[3].status, lu.NodeStatus.PASS )

        lu.assertEquals( runner.result.tests[4].testName,"MyTestToto1.test3" )
        lu.assertEquals( runner.result.tests[4].number, 4 )
        lu.assertEquals( runner.result.tests[4].className, 'MyTestToto1' )
        lu.assertEquals( runner.result.tests[4].status, lu.NodeStatus.PASS )

        lu.assertEquals( runner.result.tests[5].testName,"MyTestToto1.testa" )
        lu.assertEquals( runner.result.tests[5].number, 5 )
        lu.assertEquals( runner.result.tests[5].className, 'MyTestToto1' )
        lu.assertEquals( runner.result.tests[5].status, lu.NodeStatus.PASS )

        lu.assertEquals( runner.result.tests[6].testName,"MyTestToto1.testb" )
        lu.assertEquals( runner.result.tests[6].number, 6 )
        lu.assertEquals( runner.result.tests[6].className, 'MyTestToto1' )
        lu.assertEquals( runner.result.tests[6].status, lu.NodeStatus.PASS )

        lu.assertEquals( runner.result.tests[7].testName,"MyTestFunction" )
        lu.assertEquals( runner.result.tests[7].number, 7)
        lu.assertEquals( runner.result.tests[7].className, '[TestFunctions]' )
        lu.assertEquals( runner.result.tests[7].status,  lu.NodeStatus.PASS )

    end

    function TestLuaUnitResults:test_runSuiteWithFailures()
        local runner = lu.LuaUnit:new()
        runner:setOutputType( "NIL" )
        runner:runSuite( 'MyTestWithFailures' )

        lu.assertEquals( #runner.result.tests, 3 )
        lu.assertEquals( #runner.result.failures, 2 )

        lu.assertEquals( runner.result.tests[1].number, 1 )
        lu.assertEquals( runner.result.tests[1].testName, "MyTestWithFailures.testOk" )
        lu.assertEquals( runner.result.tests[1].className, 'MyTestWithFailures' )
        lu.assertEquals( runner.result.tests[1].status, lu.NodeStatus.PASS )
        lu.assertIsNumber( runner.result.tests[1].duration )
        lu.assertIsNil( runner.result.tests[1].msg )
        lu.assertIsNil( runner.result.tests[1].stackTrace )

        lu.assertEquals( runner.result.tests[2].testName, 'MyTestWithFailures.testWithFailure1' )
        lu.assertEquals( runner.result.tests[2].className, 'MyTestWithFailures' )
        lu.assertEquals( runner.result.tests[2].status, lu.NodeStatus.FAIL )
        lu.assertIsString( runner.result.tests[2].msg )
        lu.assertIsString( runner.result.tests[2].stackTrace )

        lu.assertEquals( runner.result.tests[3].testName, 'MyTestWithFailures.testWithFailure2' )
        lu.assertEquals( runner.result.tests[3].className, 'MyTestWithFailures' )
        lu.assertEquals( runner.result.tests[3].status, lu.NodeStatus.FAIL )
        lu.assertIsString( runner.result.tests[3].msg )
        lu.assertIsString( runner.result.tests[3].stackTrace )

        lu.assertEquals( runner.result.failures[1].testName, 'MyTestWithFailures.testWithFailure1' )
        lu.assertEquals( runner.result.failures[1].className, 'MyTestWithFailures' )
        lu.assertEquals( runner.result.failures[1].status, lu.NodeStatus.FAIL )
        lu.assertIsString( runner.result.failures[1].msg )
        lu.assertIsString( runner.result.failures[1].stackTrace )

        lu.assertEquals( runner.result.failures[2].testName, 'MyTestWithFailures.testWithFailure2' )
        lu.assertEquals( runner.result.failures[2].className, 'MyTestWithFailures' )
        lu.assertEquals( runner.result.failures[2].status, lu.NodeStatus.FAIL )
        lu.assertIsString( runner.result.failures[2].msg )
        lu.assertIsString( runner.result.failures[2].stackTrace )
    end

    function TestLuaUnitResults:test_resultsWhileTestInProgress()
        local runner = lu.LuaUnit:new()
        local MyMocker = {}
        MyMocker.new = function()
            local t = Mock:new()
            t.startTest = function(self, testName ) 
                if self.result.currentNode.number == 1 then
                    lu.assertEquals( self.result.currentNode.number, 1 )
                    lu.assertEquals( self.result.currentNode.testName, 'MyTestWithFailures.testOk' )
                    lu.assertEquals( self.result.currentNode.className, 'MyTestWithFailures' )
                    lu.assertEquals( self.result.currentNode.status, lu.NodeStatus.PASS )
                elseif self.result.currentNode.number == 2 then
                    lu.assertEquals( self.result.currentNode.number, 2 )
                    lu.assertEquals( self.result.currentNode.testName, 'MyTestWithFailures.testWithFailure1' )
                    lu.assertEquals( self.result.currentNode.className, 'MyTestWithFailures' )
                    lu.assertEquals( self.result.currentNode.status, lu.NodeStatus.PASS )
                end
            end
            t.endTest = function(self, status)
                if self.result.currentNode.number == 1 then
                    lu.assertEquals( self.result.currentNode.status, lu.NodeStatus.PASS )
                elseif self.result.currentNode.number == 2 then
                    lu.assertEquals( self.result.currentNode.status, lu.NodeStatus.FAIL )
                end
            end
            return t
        end
        runner.outputType = MyMocker
        runner:runSuite( 'MyTestWithFailures' )
        m = runner.output

        lu.assertEquals( m.calls[1][1], 'startSuite' )
        lu.assertEquals(#m.calls[1], 2 )
    end

-- To execute me , use: lua run_unit_tests.lua
