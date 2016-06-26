--[[ 
Author: Philippe Fremy <phil@freehackers.org>
License: BSD License, see LICENSE.txt

]]--

-- Return a function that appends its arguments to the `callInfo` table
local function callRecorder( callInfo )
    return function( ... )
        for i, v in pairs({...}) do
            table.insert( callInfo, v )
        end
    end
end

-- This is a bit tricky since the test uses the features that it tests.

local lu = require('luaunit')

local Mock = { __class__ = 'Mock' }

function Mock.new(runner)
    local t = lu.genericOutput.new(runner)
    t.calls = {}
    local t_MT = {
        __index = function( t, key )
            local callInfo = { key }
            table.insert( t.calls, callInfo )
            return callRecorder( callInfo )
        end
    }
    return setmetatable( t, t_MT )
end


TestMock = {}
    function TestMock:testMock()
        local m = Mock.new()
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

TestLuaUnitUtilities = { __class__ = 'TestLuaUnitUtilities' }

    function TestLuaUnitUtilities:test_genSortedIndex()
        lu.assertEquals( lu.private.__genSortedIndex( { 2, 5, 7} ), {1,2,3} )
        lu.assertEquals( lu.private.__genSortedIndex( { a='1', h='2', c='3' } ), {'a', 'c', 'h'} )
        lu.assertEquals( lu.private.__genSortedIndex( { 1, 'z', a='1', h='2', c='3' } ), { 1, 2, 'a', 'c', 'h' } )
        lu.assertEquals( lu.private.__genSortedIndex( { b=4, a=3, true, foo="bar", nil, bar=false, 42, c=5 } ),
                                                      { 1, 3, 'a', 'b', 'bar', 'c', 'foo' } )
    end

    function TestLuaUnitUtilities:test_sortedNextWorks()
        local t1 = {}
        t1['aaa'] = 'abc'
        t1['ccc'] = 'def'
        t1['bbb'] = 'cba'

        -- mimic semantics of "generic for" loop
        local sortedNext, state = lu.private.sortedPairs(t1)

        local k, v = sortedNext( state, nil )
        lu.assertEquals( k, 'aaa' )
        lu.assertEquals( v, 'abc' )
        k, v = sortedNext( state, k )
        lu.assertEquals( k, 'bbb' )
        lu.assertEquals( v, 'cba' )
        k, v = sortedNext( state, k )
        lu.assertEquals( k, 'ccc' )
        lu.assertEquals( v, 'def' )
        k, v = sortedNext( state, k )
        lu.assertEquals( k, nil )
        lu.assertEquals( v, nil )

        -- check if starting the iteration a second time works
        k, v = sortedNext( state, nil )
        lu.assertEquals( k, 'aaa' )
        lu.assertEquals( v, 'abc' )

        -- run a generic for loop (internally using a separate state)
        local tested = {}
        for k, v in lu.private.sortedPairs(t1) do table.insert(tested, v) end
        lu.assertEquals( tested, {'abc', 'cba', 'def'} )

        -- test bisection algorithm by searching for non-existing key values
        k, v = sortedNext( state, '' ) -- '' would come before any of the keys
        lu.assertNil( k )
        lu.assertNil( v )
        k, v = sortedNext( state, 'xyz' ) -- 'xyz' would be after any other key
        lu.assertNil( k )
        lu.assertNil( v )

        -- finally let's see if we successfully find an "out of sequence" key
        k, v = sortedNext( state, 'bbb' )
        lu.assertEquals( k, 'ccc' )
        lu.assertEquals( v, 'def' )
    end

    function TestLuaUnitUtilities:test_sortedNextWorksOnTwoTables()
        local t1 = { aaa = 'abc', ccc = 'def' }
        local t2 = { ['3'] = '33', ['1'] = '11' }

        local sortedNext, state1, state2
        sortedNext, state1 = lu.private.sortedPairs(t1)
        sortedNext, state2 = lu.private.sortedPairs(t2)

        local k, v = sortedNext( state1, nil )
        lu.assertEquals( k, 'aaa' )
        lu.assertEquals( v, 'abc' )

        k, v = sortedNext( state2, nil )
        lu.assertEquals( k, '1' )
        lu.assertEquals( v, '11' )

        k, v = sortedNext( state1, 'aaa' )
        lu.assertEquals( k, 'ccc' )
        lu.assertEquals( v, 'def' )

        k, v = sortedNext( state2, '1' )
        lu.assertEquals( k, '3' )
        lu.assertEquals( v, '33' )
    end

    function TestLuaUnitUtilities:test_strSplitOneCharDelim()
        local t = lu.private.strsplit( '\n', '1\n22\n333\n' )
        lu.assertEquals( t[1], '1')
        lu.assertEquals( t[2], '22')
        lu.assertEquals( t[3], '333')
        lu.assertEquals( t[4], '')
        lu.assertEquals( #t, 4 )
        -- test invalid (empty) delimiter
        lu.assertErrorMsgContains('delimiter matches empty string!',
                                  lu.private.strsplit, '', '1\n22\n333\n')
    end

    function TestLuaUnitUtilities:test_strSplit3CharDelim()
        local t = lu.private.strsplit( '2\n3', '1\n22\n332\n3' )
        lu.assertEquals( t[1], '1\n2')
        lu.assertEquals( t[2], '3')
        lu.assertEquals( t[3], '')
        lu.assertEquals( #t, 3 )
    end

    function TestLuaUnitUtilities:test_protectedCall()
        local function boom() error("Something went wrong.") end
        local err = lu.LuaUnit:protectedCall(nil, boom, "kaboom")

        -- check that err received the expected fields
        lu.assertEquals(err.status, "ERROR")
        lu.assertStrContains(err.msg, "Something went wrong.")
        lu.assertStrMatches(err.trace, "^stack traceback:.*in %a+ 'kaboom'.*")
    end

    function TestLuaUnitUtilities:test_prefixString()
        lu.assertEquals( lu.private.prefixString( '12 ', 'ab\ncd\nde'), '12 ab\n12 cd\n12 de' )
    end

    function TestLuaUnitUtilities:test_is_table_equals()
        -- Make sure that _is_table_equals() doesn't fall for these traps
        -- (See https://github.com/bluebird75/luaunit/issues/48)
        local A, B, C = {}, {}, {}

        A.self = A
        B.self = B
        lu.assertNotEquals(A, B)
        lu.assertEquals(A, A)

        A, B = {}, {}
        A.circular = C
        B.circular = A
        C.circular = B
        lu.assertNotEquals(A, B)
        lu.assertEquals(C, C)
    end

    function TestLuaUnitUtilities:test_table_keytostring()
        lu.assertEquals( lu.private._table_keytostring( 'a' ), 'a' )
        lu.assertEquals( lu.private._table_keytostring( 'a0' ), 'a0' )
        lu.assertEquals( lu.private._table_keytostring( 'a0!' ), '"a0!"' )
    end

    function TestLuaUnitUtilities:test_prettystr()
        lu.assertEquals( lu.prettystr( 1 ), "1" )
        lu.assertEquals( lu.prettystr( 1.1 ), "1.1" )
        lu.assertEquals( lu.prettystr( 'abc' ), '"abc"' )
        lu.assertEquals( lu.prettystr( 'ab\ncd' ), '"ab\ncd"' )
        lu.assertEquals( lu.prettystr( 'ab\ncd', true ), '"ab\\ncd"' )
        lu.assertEquals( lu.prettystr( 'ab"cd' ), "'ab\"cd'" )
        lu.assertEquals( lu.prettystr( "ab'cd" ), '"ab\'cd"' )
        lu.assertEquals( lu.prettystr( {1,2,3} ), "{1, 2, 3}" )
        lu.assertEquals( lu.prettystr( {a=1,bb=2,ab=3} ), '{a=1, ab=3, bb=2}' )
        lu.assertEquals( lu.prettystr( { [{}] = 1 }), '{{}=1}' )
        lu.assertEquals( lu.prettystr( { 1, [{}] = 1, 2 }), '{1, 2, {}=1}' )
        lu.assertEquals( lu.prettystr( { 1, [{one=1}] = 1, 2, "test", false }), '{1, 2, "test", false, {one=1}=1}' )
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

    function TestLuaUnitUtilities:test_prettystrTableRecursion()
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

    function TestLuaUnitUtilities:test_prettystrPadded()
        local foo, bar, str1, str2

        -- test all combinations of: foo = nil, "foo", "fo\no" (embedded
        -- newline); and bar = nil, "bar", "bar\n" (trailing newline)

        str1, str2 = lu.private.prettystrPadded(foo, bar)
        lu.assertEquals(str1, "nil")
        lu.assertEquals(str2, "nil")
        str1, str2 = lu.private.prettystrPadded(foo, bar, "_A", "_B")
        lu.assertEquals(str1, "nil_B")
        lu.assertEquals(str2, "nil")

        bar = "bar"
        str1, str2 = lu.private.prettystrPadded(foo, bar)
        lu.assertEquals(str1, "nil")
        lu.assertEquals(str2, '"bar"')
        str1, str2 = lu.private.prettystrPadded(foo, bar, "_A", "_B")
        lu.assertEquals(str1, "nil_B")
        lu.assertEquals(str2, '"bar"')

        bar = "bar\n"
        str1, str2 = lu.private.prettystrPadded(foo, bar)
        lu.assertEquals(str1, "\nnil")
        lu.assertEquals(str2, '\n"bar\n"')
        str1, str2 = lu.private.prettystrPadded(foo, bar, "_A", "_B")
        lu.assertEquals(str1, "\nnil_A")
        lu.assertEquals(str2, '\n"bar\n"')

        foo = "foo"
        bar = nil
        str1, str2 = lu.private.prettystrPadded(foo, bar)
        lu.assertEquals(str1, '"foo"')
        lu.assertEquals(str2, "nil")
        str1, str2 = lu.private.prettystrPadded(foo, bar, "_A", "_B")
        lu.assertEquals(str1, '"foo"_B')
        lu.assertEquals(str2, "nil")

        bar = "bar"
        str1, str2 = lu.private.prettystrPadded(foo, bar)
        lu.assertEquals(str1, '"foo"')
        lu.assertEquals(str2, '"bar"')
        str1, str2 = lu.private.prettystrPadded(foo, bar, "_A", "_B")
        lu.assertEquals(str1, '"foo"_B')
        lu.assertEquals(str2, '"bar"')

        bar = "bar\n"
        str1, str2 = lu.private.prettystrPadded(foo, bar)
        lu.assertEquals(str1, '\n"foo"')
        lu.assertEquals(str2, '\n"bar\n"')
        str1, str2 = lu.private.prettystrPadded(foo, bar, "_A", "_B")
        lu.assertEquals(str1, '\n"foo"_A')
        lu.assertEquals(str2, '\n"bar\n"')

        foo = "fo\no"
        bar = nil
        str1, str2 = lu.private.prettystrPadded(foo, bar)
        lu.assertEquals(str1, '\n"fo\no"')
        lu.assertEquals(str2, "\nnil")
        str1, str2 = lu.private.prettystrPadded(foo, bar, "_A", "_B")
        lu.assertEquals(str1, '\n"fo\no"_A')
        lu.assertEquals(str2, "\nnil")

        bar = "bar"
        str1, str2 = lu.private.prettystrPadded(foo, bar)
        lu.assertEquals(str1, '\n"fo\no"')
        lu.assertEquals(str2, '\n"bar"')
        str1, str2 = lu.private.prettystrPadded(foo, bar, "_A", "_B")
        lu.assertEquals(str1, '\n"fo\no"_A')
        lu.assertEquals(str2, '\n"bar"')

        bar = "bar\n"
        str1, str2 = lu.private.prettystrPadded(foo, bar)
        lu.assertEquals(str1, '\n"fo\no"')
        lu.assertEquals(str2, '\n"bar\n"')
        str1, str2 = lu.private.prettystrPadded(foo, bar, "_A", "_B")
        lu.assertEquals(str1, '\n"fo\no"_A')
        lu.assertEquals(str2, '\n"bar\n"')
    end

    function TestLuaUnitUtilities:test_FailFmt()
        -- raise failure from within nested functions
        local function bar(level)
            lu.private.fail_fmt(level, "hex=%X", 123)
        end
        local function foo(level)
            bar(level)
        end

        local _, err = pcall(foo) -- default level 1 = error position in bar()
        local line1, prefix = err:match("test[\\/]test_luaunit%.lua:(%d+): (.*)hex=7B$")
        lu.assertEquals(prefix, lu.FAILURE_PREFIX)
        lu.assertNotNil(line1)
        _, err = pcall(foo, 2) -- level 2 = error position within foo()
        local line2, prefix = err:match("test[\\/]test_luaunit%.lua:(%d+): (.*)hex=7B$")
        lu.assertEquals(prefix, lu.FAILURE_PREFIX)
        lu.assertNotNil(line2)
        -- make sure that "line2" position is exactly 3 lines after "line1"
        lu.assertEquals(tonumber(line2), tonumber(line1) + 3)
    end

    function TestLuaUnitUtilities:test_IsFunction()
        -- previous LuaUnit.isFunction was superseded by LuaUnit.asFunction
        -- (which can also serve as a boolean expression)
        lu.assertNotNil( lu.LuaUnit.asFunction( function (a,b) end ) )
        lu.assertNil( lu.LuaUnit.asFunction( nil ) )
        lu.assertNil( lu.LuaUnit.asFunction( "not a function" ) )
    end

    function TestLuaUnitUtilities:test_IsClassMethod()
        lu.assertEquals( lu.LuaUnit.isClassMethod( 'toto' ), false )
        lu.assertEquals( lu.LuaUnit.isClassMethod( 'toto.titi' ), true )
    end

    function TestLuaUnitUtilities:test_splitClassMethod()
        lu.assertEquals( lu.LuaUnit.splitClassMethod( 'toto' ), nil )
        local v1, v2 = lu.LuaUnit.splitClassMethod( 'toto.titi' )
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
        local myTestToto1Value = { 'MyTestToto1.test1', MyTestToto1 }

        local included, excluded = lu.LuaUnit.applyPatternFilter( nil, { myTestToto1Value } )
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

local function assertFailure( ... )
    -- ensure that execution generates a failure type error
    lu.assertErrorMsgMatches(lu.FAILURE_PREFIX .. ".*", ...)
end

local function assertBadFindArgTable( ... )
    lu.assertErrorMsgMatches( ".* bad argument .* to 'find' %(string expected, got table%)", ...)
end
local function assertBadFindArgNil( ... )
    lu.assertErrorMsgMatches( ".* bad argument .* to 'find' %(string expected, got nil%)", ...)
end
local function assertBadIndexNumber( ... )
    lu.assertErrorMsgMatches( ".* attempt to index .*a number value.*", ... )
end
local function assertBadIndexNil( ... )
    lu.assertErrorMsgMatches( ".* attempt to index .*a nil value.*", ... )
end
local function assertBadMethodNil( ... )
    lu.assertErrorMsgMatches( ".* attempt to call .*a nil value.*", ... )
end

TestLuaUnitAssertions = { __class__ = 'TestLuaUnitAssertions' }

    function TestLuaUnitAssertions:test_assertEquals()
        local f = function() return true end
        local g = function() return true end

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
        local config_saved = lu.TABLE_EQUALS_KEYBYCONTENT
        lu.TABLE_EQUALS_KEYBYCONTENT = false
        assertFailure( lu.assertEquals, {[{}] = 1}, { [{}] = 1})
        assertFailure( lu.assertEquals, {[{one=1, two=2}] = 1}, { [{two=2, one=1}] = 1})
        lu.TABLE_EQUALS_KEYBYCONTENT = true
        lu.assertEquals( {[{}] = 1}, { [{}] = 1})
        lu.assertEquals( {[{one=1, two=2}] = 1}, { [{two=2, one=1}] = 1})

        assertFailure( lu.assertEquals, 1, 2)
        assertFailure( lu.assertEquals, 1, "abc" )
        assertFailure( lu.assertEquals, 0, nil )
        assertFailure( lu.assertEquals, false, nil )
        assertFailure( lu.assertEquals, true, 1 )
        assertFailure( lu.assertEquals, f, 1 )
        assertFailure( lu.assertEquals, f, g )
        assertFailure( lu.assertEquals, {1,2,3}, {2,1,3} )
        assertFailure( lu.assertEquals, {1,2,3}, nil )
        assertFailure( lu.assertEquals, {1,2,3}, 1 )
        assertFailure( lu.assertEquals, {1,2,3}, true )
        assertFailure( lu.assertEquals, {1,2,3}, {one=1,two=2,three=3} )
        assertFailure( lu.assertEquals, {1,2,3}, {one=1,two=2,three=3,four=4} )
        assertFailure( lu.assertEquals, {one=1,two=2,three=3}, {2,1,3} )
        assertFailure( lu.assertEquals, {one=1,two=2,three=3}, nil )
        assertFailure( lu.assertEquals, {one=1,two=2,three=3}, 1 )
        assertFailure( lu.assertEquals, {one=1,two=2,three=3}, true )
        assertFailure( lu.assertEquals, {one=1,two=2,three=3}, {1,2,3} )
        assertFailure( lu.assertEquals, {one=1,two={1,2},three=3}, {two={2,1},three=3,one=1})
        lu.TABLE_EQUALS_KEYBYCONTENT = true -- without it, these tests won't pass anyway
        assertFailure( lu.assertEquals, {[{}] = 1}, {[{}] = 2})
        assertFailure( lu.assertEquals, {[{}] = 1}, {[{one=1}] = 2})
        assertFailure( lu.assertEquals, {[{}] = 1}, {[{}] = 1, 2})
        assertFailure( lu.assertEquals, {[{}] = 1}, {[{}] = 1, [{}] = 1})
        lu.TABLE_EQUALS_KEYBYCONTENT = config_saved
    end

    function TestLuaUnitAssertions:test_assertAlmostEquals()
        lu.assertAlmostEquals( 1, 1, 0.1 )
        lu.assertAlmostEquals( 1, 1, 0 ) -- zero margin

        lu.assertAlmostEquals( 1, 1.1, 0.2 )
        lu.assertAlmostEquals( -1, -1.1, 0.2 )
        lu.assertAlmostEquals( 0.1, -0.1, 0.3 )

        lu.assertAlmostEquals( 1, 1.1, 0.1 )
        lu.assertAlmostEquals( -1, -1.1, 0.1 )
        lu.assertAlmostEquals( 0.1, -0.1, 0.2 )

        assertFailure( lu.assertAlmostEquals, 1, 1.11, 0.1 )
        assertFailure( lu.assertAlmostEquals, -1, -1.11, 0.1 )
        lu.assertErrorMsgContains( "must supply only number arguments", lu.assertAlmostEquals, -1, 1, nil )
        lu.assertErrorMsgContains( "must supply only number arguments", lu.assertAlmostEquals, -1, nil, 0 )
        lu.assertErrorMsgContains( "must supply only number arguments", lu.assertAlmostEquals, nil, 1, 0 )
        lu.assertErrorMsgContains( "margin must not be negative", lu.assertAlmostEquals, 1, 1.1, -0.1 )
    end

    function TestLuaUnitAssertions:test_assertNotEquals()
        local f = function() return true end
        local g = function() return true end

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

        assertFailure( lu.assertNotEquals, 1, 1)
        assertFailure( lu.assertNotEquals, "abc", "abc" )
        assertFailure( lu.assertNotEquals, nil, nil )
        assertFailure( lu.assertNotEquals, true, true )
        assertFailure( lu.assertNotEquals, f, f)
        assertFailure( lu.assertNotEquals, {one=1,two={1,{2,nil}},three=3}, {two={1,{2,nil}},three=3,one=1})
    end

    function TestLuaUnitAssertions:test_assertNotAlmostEquals()
        lu.assertNotAlmostEquals( 1, 1.2, 0.1 )
        lu.assertNotAlmostEquals( 1, 1.01, 0 ) -- zero margin

        lu.assertNotAlmostEquals( 1, 1.3, 0.2 )
        lu.assertNotAlmostEquals( -1, -1.3, 0.2 )
        lu.assertNotAlmostEquals( 0.1, -0.1, 0.1 )

        lu.assertNotAlmostEquals( 1, 1.1, 0.09 )
        lu.assertNotAlmostEquals( -1, -1.1, 0.09 )
        lu.assertNotAlmostEquals( 0.1, -0.1, 0.11 )

        assertFailure( lu.assertNotAlmostEquals, 1, 1.11, 0.2 )
        assertFailure( lu.assertNotAlmostEquals, -1, -1.11, 0.2 )
        lu.assertErrorMsgContains( "must supply only number arguments", lu.assertNotAlmostEquals, -1, 1, nil )
        lu.assertErrorMsgContains( "must supply only number arguments", lu.assertNotAlmostEquals, -1, nil, 0 )
        lu.assertErrorMsgContains( "must supply only number arguments", lu.assertNotAlmostEquals, nil, 1, 0 )
        lu.assertErrorMsgContains( "margin must not be negative", lu.assertNotAlmostEquals, 1, 1.1, -0.1 )
    end

    function TestLuaUnitAssertions:test_assertNotEqualsDifferentTypes2()
        lu.assertNotEquals( 2, "abc" )
    end

    function TestLuaUnitAssertions:test_assertTrue()
        lu.assertTrue(true)
        assertFailure( lu.assertTrue, false)
        lu.assertTrue(0)
        lu.assertTrue(1)
        lu.assertTrue("")
        lu.assertTrue("abc")
        assertFailure( lu.assertTrue, nil )
        lu.assertTrue( function() return true end )
        lu.assertTrue( {} )
        lu.assertTrue( { 1 } )
    end

    function TestLuaUnitAssertions:test_assertFalse()
        lu.assertFalse(false)
        assertFailure( lu.assertFalse, true)
        lu.assertFalse( nil )
        assertFailure( lu.assertFalse, 0 )
        assertFailure( lu.assertFalse, 1 )
        assertFailure( lu.assertFalse, "" )
        assertFailure( lu.assertFalse, "abc" )
        assertFailure( lu.assertFalse, function() return true end )
        assertFailure( lu.assertFalse, {} )
        assertFailure( lu.assertFalse, { 1 } )
    end

    function TestLuaUnitAssertions:test_assertNil()
        lu.assertNil(nil)
        assertFailure( lu.assertTrue, false)
        assertFailure( lu.assertNil, 0)
        assertFailure( lu.assertNil, "")
        assertFailure( lu.assertNil, "abc")
        assertFailure( lu.assertNil,  function() return true end )
        assertFailure( lu.assertNil,  {} )
        assertFailure( lu.assertNil,  { 1 } )
    end

    function TestLuaUnitAssertions:test_assertNotNil()
        assertFailure( lu.assertNotNil, nil)
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
        assertFailure( lu.assertStrContains, 'ABCDEF', 'abc' )
        assertFailure( lu.assertStrContains, '', 'abc' )
        lu.assertStrContains( 'abcdef', '' )
        assertFailure( lu.assertStrContains, 'abcdef', 'abcx' )
        assertFailure( lu.assertStrContains, 'abcdef', 'abcdefg' )
        assertFailure( lu.assertStrContains, 'abcdef', 0 )
        assertBadFindArgTable( lu.assertStrContains, 'abcdef', {} )
        assertBadFindArgNil( lu.assertStrContains, 'abcdef', nil )

        lu.assertStrContains( 'abcdef', 'abc', false )
        lu.assertStrContains( 'abcdef', 'abc', true )
        lu.assertStrContains( 'abcdef', 'a.c', true )

        assertFailure( lu.assertStrContains, 'abcdef', '.abc', true )
    end

    function TestLuaUnitAssertions:test_assertStrIContains()
        lu.assertStrIContains( 'ABcdEF', 'aBc' )
        lu.assertStrIContains( 'abCDef', 'bcd' )
        lu.assertStrIContains( 'abcdef', 'abcDef' )
        assertFailure( lu.assertStrIContains, '', 'aBc' )
        lu.assertStrIContains( 'abcDef', '' )
        assertFailure( lu.assertStrIContains, 'abcdef', 'abcx' )
        assertFailure( lu.assertStrIContains, 'abcdef', 'abcdefg' )
    end

    function TestLuaUnitAssertions:test_assertNotStrContains()
        assertFailure( lu.assertNotStrContains, 'abcdef', 'abc' )
        assertFailure( lu.assertNotStrContains, 'abcdef', 'bcd' )
        assertFailure( lu.assertNotStrContains, 'abcdef', 'abcdef' )
        lu.assertNotStrContains( '', 'abc' )
        assertFailure( lu.assertNotStrContains, 'abcdef', '' )
        assertFailure( lu.assertNotStrContains, 'abc0', 0 )
        lu.assertNotStrContains( 'abcdef', 'abcx' )
        lu.assertNotStrContains( 'abcdef', 'abcdefg' )
        assertBadFindArgTable( lu.assertNotStrContains, 'abcdef', {} )
        assertBadFindArgNil( lu.assertNotStrContains, 'abcdef', nil )

        assertFailure( lu.assertNotStrContains, 'abcdef', 'abc', false )
        assertFailure( lu.assertNotStrContains, 'abcdef', 'a.c', true )
        lu.assertNotStrContains( 'abcdef', 'a.cx', true )
    end

    function TestLuaUnitAssertions:test_assertNotStrIContains()
        assertFailure( lu.assertNotStrIContains, 'aBcdef', 'abc' )
        assertFailure( lu.assertNotStrIContains, 'abcdef', 'aBc' )
        assertFailure( lu.assertNotStrIContains, 'abcdef', 'bcd' )
        assertFailure( lu.assertNotStrIContains, 'abcdef', 'abcdef' )
        lu.assertNotStrIContains( '', 'abc' )
        assertFailure( lu.assertNotStrIContains, 'abcdef', '' )
        assertBadIndexNumber( lu.assertNotStrIContains, 'abc0', 0 )
        lu.assertNotStrIContains( 'abcdef', 'abcx' )
        lu.assertNotStrIContains( 'abcdef', 'abcdefg' )
        assertBadMethodNil( lu.assertNotStrIContains, 'abcdef', {} )
        assertBadIndexNil( lu.assertNotStrIContains, 'abcdef', nil )
    end

    function TestLuaUnitAssertions:test_assertStrMatches()
        lu.assertStrMatches( 'abcdef', 'abcdef' )
        lu.assertStrMatches( 'abcdef', '..cde.' )
        assertFailure( lu.assertStrMatches, 'abcdef', '..def')
        assertFailure( lu.assertStrMatches, 'abCDEf', '..cde.')
        lu.assertStrMatches( 'abcdef', 'bcdef', 2 )
        lu.assertStrMatches( 'abcdef', 'bcde', 2, 5 )
        lu.assertStrMatches( 'abcdef', 'b..e', 2, 5 )
        lu.assertStrMatches( 'abcdef', 'ab..e', nil, 5 )
        assertFailure( lu.assertStrMatches, 'abcdef', '' )
        assertFailure( lu.assertStrMatches, '', 'abcdef' )

        assertFailure( lu.assertStrMatches, 'abcdef', 0 )
        assertBadFindArgTable( lu.assertStrMatches, 'abcdef', {} )
        assertBadFindArgNil( lu.assertStrMatches, 'abcdef', nil )
    end

    function TestLuaUnitAssertions:test_assertItemsEquals()
        lu.assertItemsEquals(nil, nil)
        lu.assertItemsEquals({},{})
        lu.assertItemsEquals({1,2,3}, {3,1,2})
        lu.assertItemsEquals({nil},{nil})
        lu.assertItemsEquals({one=1,two=2,three=3}, {two=2,one=1,three=3})
        lu.assertItemsEquals({one=1,two=2,three=3}, {a=1,b=2,c=3})
        lu.assertItemsEquals({1,2,three=3}, {3,1,two=2})

        assertFailure(lu.assertItemsEquals, {1}, {})
        assertFailure(lu.assertItemsEquals, nil, {1,2,3})
        assertFailure(lu.assertItemsEquals, {1,2,3}, nil)
        assertFailure(lu.assertItemsEquals, {1,2,3,4}, {3,1,2})
        assertFailure(lu.assertItemsEquals, {1,2,3}, {3,1,2,4})
        assertFailure(lu.assertItemsEquals, {one=1,two=2,three=3,four=4}, {a=1,b=2,c=3})
        assertFailure(lu.assertItemsEquals, {one=1,two=2,three=3}, {a=1,b=2,c=3,d=4})
        assertFailure(lu.assertItemsEquals, {1,2,three=3}, {3,4,a=1,b=2})
        assertFailure(lu.assertItemsEquals, {1,2,three=3,four=4}, {3,a=1,b=2})

        lu.assertItemsEquals({one=1,two={1,2},three=3}, {one={1,2},two=1,three=3})
        lu.assertItemsEquals({one=1,
                           two={1,{3,2,one=1}},
                           three=3}, 
                        {two={1,{3,2,one=1}},
                         one=1,
                         three=3})
        -- itemsEquals is not recursive:
        assertFailure( lu.assertItemsEquals,{1,{2,1},3}, {3,1,{1,2}})
        assertFailure( lu.assertItemsEquals,{one=1,two={1,2},three=3}, {one={2,1},two=1,three=3})
        assertFailure( lu.assertItemsEquals,{one=1,two={1,{3,2,one=1}},three=3}, {two={{3,one=1,2},1},one=1,three=3})
        assertFailure( lu.assertItemsEquals,{one=1,two={1,{3,2,one=1}},three=3}, {two={{3,2,one=1},1},one=1,three=3})

        assertFailure(lu.assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1,three=2})
        assertFailure(lu.assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1,four=4})
        assertFailure(lu.assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1,'three'})
        assertFailure(lu.assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1,nil})
        assertFailure(lu.assertItemsEquals, {one=1,two=2,three=3}, {two=2,one=1})
    end

    function TestLuaUnitAssertions:test_assertIsNumber()
        lu.assertIsNumber(1)
        lu.assertIsNumber(1.4)
        assertFailure(lu.assertIsNumber, "hi there!")
        assertFailure(lu.assertIsNumber, nil)
        assertFailure(lu.assertIsNumber, {})
        assertFailure(lu.assertIsNumber, {1,2,3})
        assertFailure(lu.assertIsNumber, {1})
        assertFailure(lu.assertIsNumber, coroutine.create( function(v) local y=v+1 end ) )
        assertFailure(lu.assertIsNumber, true)
    end

    function TestLuaUnitAssertions:test_assertIsString()
        assertFailure(lu.assertIsString, 1)
        assertFailure(lu.assertIsString, 1.4)
        lu.assertIsString("hi there!")
        assertFailure(lu.assertIsString, nil)
        assertFailure(lu.assertIsString, {})
        assertFailure(lu.assertIsString, {1,2,3})
        assertFailure(lu.assertIsString, {1})
        assertFailure(lu.assertIsString, coroutine.create( function(v) local y=v+1 end ) )
        assertFailure(lu.assertIsString, true)
    end

    function TestLuaUnitAssertions:test_assertIsTable()
        assertFailure(lu.assertIsTable, 1)
        assertFailure(lu.assertIsTable, 1.4)
        assertFailure(lu.assertIsTable, "hi there!")
        assertFailure(lu.assertIsTable, nil)
        lu.assertIsTable({})
        lu.assertIsTable({1,2,3})
        lu.assertIsTable({1})
        assertFailure(lu.assertIsTable, true)
        assertFailure(lu.assertIsTable, coroutine.create( function(v) local y=v+1 end ) )
    end

    function TestLuaUnitAssertions:test_assertIsBoolean()
        assertFailure(lu.assertIsBoolean, 1)
        assertFailure(lu.assertIsBoolean, 1.4)
        assertFailure(lu.assertIsBoolean, "hi there!")
        assertFailure(lu.assertIsBoolean, nil)
        assertFailure(lu.assertIsBoolean, {})
        assertFailure(lu.assertIsBoolean, {1,2,3})
        assertFailure(lu.assertIsBoolean, {1})
        assertFailure(lu.assertIsBoolean, coroutine.create( function(v) local y=v+1 end ) )
        lu.assertIsBoolean(true)
        lu.assertIsBoolean(false)
    end

    function TestLuaUnitAssertions:test_assertIsNil()
        assertFailure(lu.assertIsNil, 1)
        assertFailure(lu.assertIsNil, 1.4)
        assertFailure(lu.assertIsNil, "hi there!")
        lu.assertIsNil(nil)
        assertFailure(lu.assertIsNil, {})
        assertFailure(lu.assertIsNil, {1,2,3})
        assertFailure(lu.assertIsNil, {1})
        assertFailure(lu.assertIsNil, false)
        assertFailure(lu.assertIsNil, coroutine.create( function(v) local y=v+1 end ) )
    end

    function TestLuaUnitAssertions:test_assertIsFunction()
        local f = function() return true end

        assertFailure(lu.assertIsFunction, 1)
        assertFailure(lu.assertIsFunction, 1.4)
        assertFailure(lu.assertIsFunction, "hi there!")
        assertFailure(lu.assertIsFunction, nil)
        assertFailure(lu.assertIsFunction, {})
        assertFailure(lu.assertIsFunction, {1,2,3})
        assertFailure(lu.assertIsFunction, {1})
        assertFailure(lu.assertIsFunction, false)
        assertFailure(lu.assertIsFunction, coroutine.create( function(v) local y=v+1 end ) )
        lu.assertIsFunction(f)
    end

    function TestLuaUnitAssertions:test_assertIsThread()
        assertFailure(lu.assertIsThread, 1)
        assertFailure(lu.assertIsThread, 1.4)
        assertFailure(lu.assertIsThread, "hi there!")
        assertFailure(lu.assertIsThread, nil)
        assertFailure(lu.assertIsThread, {})
        assertFailure(lu.assertIsThread, {1,2,3})
        assertFailure(lu.assertIsThread, {1})
        assertFailure(lu.assertIsThread, false)
        assertFailure(lu.assertIsThread, function(v) local y=v+1 end )
        lu.assertIsThread(coroutine.create( function(v) local y=v+1 end ) )
    end

    function TestLuaUnitAssertions:test_assertIsUserdata()
        assertFailure(lu.assertIsUserdata, 1)
        assertFailure(lu.assertIsUserdata, 1.4)
        assertFailure(lu.assertIsUserdata, "hi there!")
        assertFailure(lu.assertIsUserdata, nil)
        assertFailure(lu.assertIsUserdata, {})
        assertFailure(lu.assertIsUserdata, {1,2,3})
        assertFailure(lu.assertIsUserdata, {1})
        assertFailure(lu.assertIsUserdata, false)
        assertFailure(lu.assertIsUserdata, function(v) local y=v+1 end )
        assertFailure(lu.assertIsUserdata, coroutine.create( function(v) local y=v+1 end ) )
    end

    function TestLuaUnitAssertions:test_assertNotIsNumber()
        assertFailure(lu.assertNotIsNumber, 1 )
        assertFailure(lu.assertNotIsNumber, 1.4 )
        lu.assertNotIsNumber( "hi there!")
        lu.assertNotIsNumber( nil)
        lu.assertNotIsNumber( {})
        lu.assertNotIsNumber( {1,2,3})
        lu.assertNotIsNumber( {1})
        lu.assertNotIsNumber( coroutine.create( function(v) local y=v+1 end ) )
        lu.assertNotIsNumber( true)
    end

    function TestLuaUnitAssertions:test_assertNotIsString()
        lu.assertNotIsString( 1)
        lu.assertNotIsString( 1.4)
        assertFailure( lu.assertNotIsString, "hi there!")
        lu.assertNotIsString( nil)
        lu.assertNotIsString( {})
        lu.assertNotIsString( {1,2,3})
        lu.assertNotIsString( {1})
        lu.assertNotIsString( coroutine.create( function(v) local y=v+1 end ) )
        lu.assertNotIsString( true)
    end

    function TestLuaUnitAssertions:test_assertNotIsTable()
        lu.assertNotIsTable( 1)
        lu.assertNotIsTable( 1.4)
        lu.assertNotIsTable( "hi there!")
        lu.assertNotIsTable( nil)
        assertFailure( lu.assertNotIsTable, {})
        assertFailure( lu.assertNotIsTable, {1,2,3})
        assertFailure( lu.assertNotIsTable, {1})
        lu.assertNotIsTable( true)
        lu.assertNotIsTable( coroutine.create( function(v) local y=v+1 end ) )
    end

    function TestLuaUnitAssertions:test_assertNotIsBoolean()
        lu.assertNotIsBoolean( 1)
        lu.assertNotIsBoolean( 1.4)
        lu.assertNotIsBoolean( "hi there!")
        lu.assertNotIsBoolean( nil)
        lu.assertNotIsBoolean( {})
        lu.assertNotIsBoolean( {1,2,3})
        lu.assertNotIsBoolean( {1})
        lu.assertNotIsBoolean( coroutine.create( function(v) local y=v+1 end ) )
        assertFailure( lu.assertNotIsBoolean, true)
        assertFailure( lu.assertNotIsBoolean, false)
    end

    function TestLuaUnitAssertions:test_assertNotIsNil()
        lu.assertNotIsNil( 1)
        lu.assertNotIsNil( 1.4)
        lu.assertNotIsNil( "hi there!")
        assertFailure( lu.assertNotIsNil, nil)
        lu.assertNotIsNil( {})
        lu.assertNotIsNil( {1,2,3})
        lu.assertNotIsNil( {1})
        lu.assertNotIsNil( false)
        lu.assertNotIsNil( coroutine.create( function(v) local y=v+1 end ) )
    end

    function TestLuaUnitAssertions:test_assertNotIsFunction()
        local f = function() return true end

        lu.assertNotIsFunction( 1)
        lu.assertNotIsFunction( 1.4)
        lu.assertNotIsFunction( "hi there!")
        lu.assertNotIsFunction( nil)
        lu.assertNotIsFunction( {})
        lu.assertNotIsFunction( {1,2,3})
        lu.assertNotIsFunction( {1})
        lu.assertNotIsFunction( false)
        lu.assertNotIsFunction( coroutine.create( function(v) local y=v+1 end ) )
        assertFailure( lu.assertNotIsFunction, f)
    end

    function TestLuaUnitAssertions:test_assertNotIsThread()
        lu.assertNotIsThread( 1)
        lu.assertNotIsThread( 1.4)
        lu.assertNotIsThread( "hi there!")
        lu.assertNotIsThread( nil)
        lu.assertNotIsThread( {})
        lu.assertNotIsThread( {1,2,3})
        lu.assertNotIsThread( {1})
        lu.assertNotIsThread( false)
        lu.assertNotIsThread( function(v) local y=v+1 end )
        assertFailure( lu.assertNotIsThread, coroutine.create( function(v) local y=v+1 end ) )
    end

    function TestLuaUnitAssertions:test_assertNotIsUserdata()
        lu.assertNotIsUserdata( 1)
        lu.assertNotIsUserdata( 1.4)
        lu.assertNotIsUserdata( "hi there!")
        lu.assertNotIsUserdata( nil)
        lu.assertNotIsUserdata( {})
        lu.assertNotIsUserdata( {1,2,3})
        lu.assertNotIsUserdata( {1})
        lu.assertNotIsUserdata( false)
        lu.assertNotIsUserdata( function(v) local y=v+1 end )
        lu.assertNotIsUserdata( coroutine.create( function(v) local y=v+1 end ) )
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

        assertFailure(lu.assertIs, 1, 2)
        assertFailure(lu.assertIs, 1.4, 1)
        assertFailure(lu.assertIs, "hi there!", "hola")
        assertFailure(lu.assertIs, nil, 1)
        assertFailure(lu.assertIs, {}, {})
        assertFailure(lu.assertIs, {1,2,3}, f)
        assertFailure(lu.assertIs, f, g)
        assertFailure(lu.assertIs, t2,t3 )
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

        assertFailure( lu.assertNotIs, 1,1 )
        assertFailure( lu.assertNotIs, f,f )
        assertFailure( lu.assertNotIs, t1,t1 )
        assertFailure( lu.assertNotIs, t4,t4)
        assertFailure( lu.assertNotIs, s1,s2 )
        assertFailure( lu.assertNotIs, 'toto', 'toto' )

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


local function assertFailureEquals(msg, ...)
    lu.assertErrorMsgEquals(lu.FAILURE_PREFIX .. msg, ...)
end

local function assertFailureMatches(msg, ...)
    lu.assertErrorMsgMatches(lu.FAILURE_PREFIX .. msg, ...)
end

local function assertFailureContains(msg, ...)
    lu.assertErrorMsgContains(lu.FAILURE_PREFIX .. msg, ...)
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
        local has_error = not pcall( self.f_with_error, x )
        lu.assertEquals( has_error, true )

        -- f does not generate an error
        has_error = not pcall( self.f, x )
        lu.assertEquals( has_error, false )

        -- lu.assertError is happy with f_with_error
        lu.assertError( self.f_with_error, x )

        -- lu.assertError is unhappy with f
        assertFailureEquals( "Expected an error when calling function but no error generated",
                             lu.assertError, self.f, x )

        -- multiple arguments
        local function f_with_multi_arguments(a,b,c)
            if a == b and b == c then return end
            error("three arguments not equal")
        end

        lu.assertError( f_with_multi_arguments, 1, 1, 3 )
        lu.assertError( f_with_multi_arguments, 1, 3, 1 )
        lu.assertError( f_with_multi_arguments, 3, 1, 1 )

        assertFailureEquals( "Expected an error when calling function but no error generated",
                             lu.assertError, f_with_multi_arguments, 1, 1, 1 )
    end

    function TestLuaUnitAssertionsError:test_assertErrorMsgContains()
        local x = 1
        assertFailure( lu.assertErrorMsgContains, 'toto', self.f, x )
        lu.assertErrorMsgContains( 'is an err', self.f_with_error, x )
        lu.assertErrorMsgContains( 'This is an error', self.f_with_error, x )
        assertFailure( lu.assertErrorMsgContains, ' This is an error', self.f_with_error, x )
        assertFailure( lu.assertErrorMsgContains, 'This .. an error', self.f_with_error, x )
    end

    function TestLuaUnitAssertionsError:test_assertErrorMsgEquals()
        local x = 1
        assertFailure( lu.assertErrorMsgEquals, 'toto', self.f, x )
        assertFailure( lu.assertErrorMsgEquals, 'is an err', self.f_with_error, x )
        lu.assertErrorMsgEquals( 'This is an error', self.f_with_error, x )
        assertFailure( lu.assertErrorMsgEquals, ' This is an error', self.f_with_error, x )
        assertFailure( lu.assertErrorMsgEquals, 'This .. an error', self.f_with_error, x )
    end

    function TestLuaUnitAssertionsError:test_assertErrorMsgMatches()
        local x = 1
        assertFailure( lu.assertErrorMsgMatches, 'toto', self.f, x )
        assertFailure( lu.assertErrorMsgMatches, 'is an err', self.f_with_error, x )
        lu.assertErrorMsgMatches( 'This is an error', self.f_with_error, x )
        lu.assertErrorMsgMatches( 'This is .. error', self.f_with_error, x )
        assertFailure( lu.assertErrorMsgMatches, ' This is an error', self.f_with_error, x )
    end

------------------------------------------------------------------
--
--                       Failure message tests
--
------------------------------------------------------------------

TestLuaUnitErrorMsg = { __class__ = 'TestLuaUnitErrorMsg' }

    function TestLuaUnitErrorMsg:setUp()
        self.old_ORDER_ACTUAL_EXPECTED = lu.ORDER_ACTUAL_EXPECTED
        self.old_PRINT_TABLE_REF_IN_ERROR_MSG = lu.PRINT_TABLE_REF_IN_ERROR_MSG
    end

    function TestLuaUnitErrorMsg:tearDown()
        lu.ORDER_ACTUAL_EXPECTED = self.old_ORDER_ACTUAL_EXPECTED
        lu.PRINT_TABLE_REF_IN_ERROR_MSG = self.old_PRINT_TABLE_REF_IN_ERROR_MSG
    end

    function TestLuaUnitErrorMsg:test_assertEqualsMsg()
        assertFailureEquals( 'expected: 2, actual: 1', lu.assertEquals, 1, 2  )
        assertFailureEquals( 'expected: "exp"\nactual: "act"', lu.assertEquals, 'act', 'exp' )
        assertFailureEquals( 'expected: \n"exp\npxe"\nactual: \n"act\ntca"', lu.assertEquals, 'act\ntca', 'exp\npxe' )
        assertFailureEquals( 'expected: true, actual: false', lu.assertEquals, false, true )
        if _VERSION == 'Lua 5.3' then
            assertFailureEquals( 'expected: 1.2, actual: 1.0', lu.assertEquals, 1.0, 1.2)
        else
            assertFailureEquals( 'expected: 1.2, actual: 1', lu.assertEquals, 1.0, 1.2)
        end
        assertFailureMatches( 'expected: {1, 2, 3}\nactual: {3, 2, 1}', lu.assertEquals, {3,2,1}, {1,2,3} )
        assertFailureMatches( 'expected: {one=1, two=2}\nactual: {3, 2, 1}', lu.assertEquals, {3,2,1}, {one=1,two=2} )
        assertFailureEquals( 'expected: 2, actual: nil', lu.assertEquals, nil, 2 )
    end 

    function TestLuaUnitErrorMsg:test_assertEqualsOrderReversedMsg()
        lu.ORDER_ACTUAL_EXPECTED = false
        assertFailureEquals( 'expected: 1, actual: 2', lu.assertEquals, 1, 2  )
        assertFailureEquals( 'expected: "act"\nactual: "exp"', lu.assertEquals, 'act', 'exp' )
    end 

    function TestLuaUnitErrorMsg:test_assertAlmostEqualsMsg()
        assertFailureEquals('Values are not almost equal\nExpected: 1 with margin of 0.1, received: 2', lu.assertAlmostEquals, 2, 1, 0.1 )
    end

    function TestLuaUnitErrorMsg:test_assertAlmostEqualsOrderReversedMsg()
        lu.ORDER_ACTUAL_EXPECTED = false
        assertFailureEquals('Values are not almost equal\nExpected: 2 with margin of 0.1, received: 1', lu.assertAlmostEquals, 2, 1, 0.1 )
    end

    function TestLuaUnitErrorMsg:test_assertNotAlmostEqualsMsg()
        assertFailureEquals('Values are almost equal\nExpected: 1 with a difference above margin of 0.2, received: 1.1', lu.assertNotAlmostEquals, 1.1, 1, 0.2 )
    end

    function TestLuaUnitErrorMsg:test_assertNotAlmostEqualsMsg()
        lu.ORDER_ACTUAL_EXPECTED = false
        assertFailureEquals('Values are almost equal\nExpected: 1.1 with a difference above margin of 0.2, received: 1', lu.assertNotAlmostEquals, 1.1, 1, 0.2 )
    end

    function TestLuaUnitErrorMsg:test_assertNotEqualsMsg()
        assertFailureEquals( 'Received the not expected value: 1', lu.assertNotEquals, 1, 1  )
        assertFailureMatches( 'Received the not expected value: {1, 2}', lu.assertNotEquals, {1,2}, {1,2} )
        assertFailureEquals( 'Received the not expected value: nil', lu.assertNotEquals, nil, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertNotEqualsOrderReversedMsg()
        lu.ORDER_ACTUAL_EXPECTED = false
        assertFailureEquals( 'Received the not expected value: 1', lu.assertNotEquals, 1, 1  )
    end 

    function TestLuaUnitErrorMsg:test_assertTrueFalse()
        assertFailureEquals( 'expected: true, actual: false', lu.assertTrue, false )
        assertFailureEquals( 'expected: true, actual: nil', lu.assertTrue, nil )
        assertFailureEquals( 'expected: false, actual: true', lu.assertFalse, true )
        assertFailureEquals( 'expected: false, actual: 0', lu.assertFalse, 0)
        assertFailureMatches( 'expected: false, actual: {}', lu.assertFalse, {})
        assertFailureEquals( 'expected: false, actual: "abc"', lu.assertFalse, 'abc')
        assertFailureContains( 'expected: false, actual: function', lu.assertFalse, function () end )
    end 

    function TestLuaUnitErrorMsg:test_assertNil()
        assertFailureEquals( 'expected: nil, actual: false', lu.assertNil, false )
        assertFailureEquals( 'expected non nil value, received nil', lu.assertNotNil, nil )
    end

    function TestLuaUnitErrorMsg:test_assertStrContains()
        assertFailureEquals( 'Error, substring "xxx" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'xxx' )
        assertFailureEquals( 'Error, substring "aBc" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'aBc' )
        assertFailureEquals( 'Error, substring "xxx" was not found in string ""', lu.assertStrContains, '', 'xxx' )

        assertFailureEquals( 'Error, substring "xxx" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'xxx', false )
        assertFailureEquals( 'Error, substring "aBc" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'aBc', false )
        assertFailureEquals( 'Error, substring "xxx" was not found in string ""', lu.assertStrContains, '', 'xxx', false )

        assertFailureEquals( 'Error, regexp "xxx" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'xxx', true )
        assertFailureEquals( 'Error, regexp "aBc" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'aBc', true )
        assertFailureEquals( 'Error, regexp "xxx" was not found in string ""', lu.assertStrContains, '', 'xxx', true )

    end 

    function TestLuaUnitErrorMsg:test_assertStrIContains()
        assertFailureEquals( 'Error, substring "xxx" was not found in string "abcdef"', lu.assertStrContains, 'abcdef', 'xxx' )
        assertFailureEquals( 'Error, substring "xxx" was not found in string ""', lu.assertStrContains, '', 'xxx' )
    end 

    function TestLuaUnitErrorMsg:test_assertNotStrContains()
        assertFailureEquals( 'Error, substring "abc" was found in string "abcdef"', lu.assertNotStrContains, 'abcdef', 'abc' )
        assertFailureEquals( 'Error, substring "abc" was found in string "abcdef"', lu.assertNotStrContains, 'abcdef', 'abc', false )
        assertFailureEquals( 'Error, regexp "..." was found in string "abcdef"', lu.assertNotStrContains, 'abcdef', '...', true)
    end 

    function TestLuaUnitErrorMsg:test_assertNotStrIContains()
        assertFailureEquals( 'Error, substring "aBc" was found (case insensitively) in string "abcdef"', lu.assertNotStrIContains, 'abcdef', 'aBc' )
        assertFailureEquals( 'Error, substring "abc" was found (case insensitively) in string "abcdef"', lu.assertNotStrIContains, 'abcdef', 'abc' )
    end 

    function TestLuaUnitErrorMsg:test_assertStrMatches()
        assertFailureEquals('Error, pattern "xxx" was not matched by string "abcdef"', lu.assertStrMatches, 'abcdef', 'xxx' )
    end 

    function TestLuaUnitErrorMsg:test_assertIsNumber()
        assertFailureEquals( 'Expected: a number value, actual: type string, value "abc"', lu.assertIsNumber, 'abc' )
        assertFailureEquals( 'Expected: a number value, actual: type nil, value nil', lu.assertIsNumber, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertIsString()
        assertFailureEquals( 'Expected: a string value, actual: type number, value 1.2', lu.assertIsString, 1.2 )
        assertFailureEquals( 'Expected: a string value, actual: type nil, value nil', lu.assertIsString, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertIsTable()
        assertFailureEquals( 'Expected: a table value, actual: type number, value 1.2', lu.assertIsTable, 1.2 )
        assertFailureEquals( 'Expected: a table value, actual: type nil, value nil', lu.assertIsTable, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertIsBoolean()
        assertFailureEquals( 'Expected: a boolean value, actual: type number, value 1.2', lu.assertIsBoolean, 1.2 )
        assertFailureEquals( 'Expected: a boolean value, actual: type nil, value nil', lu.assertIsBoolean, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertIsFunction()
        assertFailureEquals( 'Expected: a function value, actual: type number, value 1.2', lu.assertIsFunction, 1.2 )
        assertFailureEquals( 'Expected: a function value, actual: type nil, value nil', lu.assertIsFunction, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertIsThread()
        assertFailureEquals( 'Expected: a thread value, actual: type number, value 1.2', lu.assertIsThread, 1.2 )
        assertFailureEquals( 'Expected: a thread value, actual: type nil, value nil', lu.assertIsThread, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertIsUserdata()
        assertFailureEquals( 'Expected: a userdata value, actual: type number, value 1.2', lu.assertIsUserdata, 1.2 )
        assertFailureEquals( 'Expected: a userdata value, actual: type nil, value nil', lu.assertIsUserdata, nil )
    end 

    function TestLuaUnitErrorMsg:test_assertNotIsNumber()
        assertFailureEquals( 'Not expected: a number type, actual: value 123', lu.assertNotIsNumber, 123 )
    end 

    function TestLuaUnitErrorMsg:test_assertNotIsString()
        assertFailureEquals( 'Not expected: a string type, actual: value "abc"', lu.assertNotIsString, "abc" )
    end 

    function TestLuaUnitErrorMsg:test_assertNotIsTable()
        assertFailureEquals( 'Not expected: a table type, actual: value {1, 2, 3}', lu.assertNotIsTable, {1,2,3} )
    end 

    function TestLuaUnitErrorMsg:test_assertNotIsBoolean()
        assertFailureEquals( 'Not expected: a boolean type, actual: value false', lu.assertNotIsBoolean, false )
    end 

    function TestLuaUnitErrorMsg:test_assertNotIsFunction()
        assertFailureContains( 'Not expected: a function type, actual: value function:', lu.assertNotIsFunction, function() return true end )
    end 

    function TestLuaUnitErrorMsg:test_assertNotIsThread()
        assertFailureContains( 'Not expected: a thread type, actual: value thread:', lu.assertNotIsThread, coroutine.create( function(v) local y=v+1 end ) )
    end 

    --[[ How do you create UserData ?
    function TestLuaUnitErrorMsg:test_assertIsNotUserdata()
        assertFailureEquals( 'Not expected: a userdata type, actual: value XXX ???', lu.assertIsNotUserdata, XXX ??? )
    end 
    ]]

    function TestLuaUnitErrorMsg:test_assertIs()
        assertFailureEquals( 'Expected object and actual object are not the same\nExpected: 1, actual: 2', lu.assertIs, 2, 1 )
        lu.ORDER_ACTUAL_EXPECTED = false
        assertFailureEquals( 'Expected object and actual object are not the same\nExpected: 2, actual: 1', lu.assertIs, 2, 1 )
    end 

    function TestLuaUnitErrorMsg:test_assertNotIs()
        local v = {1,2}
        assertFailureMatches( 'Expected object and actual object are the same object: {1, 2}', lu.assertNotIs, v, v )
        lu.ORDER_ACTUAL_EXPECTED = false -- order shouldn't matter here, but let's cover it
        assertFailureMatches( 'Expected object and actual object are the same object: {1, 2}', lu.assertNotIs, v, v )
    end 

    function TestLuaUnitErrorMsg:test_assertItemsEquals()
        assertFailureMatches('Contents of the tables are not identical:\nExpected: {one=2, two=3}\nActual: {1, 2}' , lu.assertItemsEquals, {1,2}, {one=2, two=3} )
        assertFailureContains('Contents of the tables are not identical' , lu.assertItemsEquals, {}, {1} ) -- actual table empty, = doesn't contain expected value
        assertFailureContains('Contents of the tables are not identical' , lu.assertItemsEquals, nil, 'foobar' ) -- type mismatch
        assertFailureContains('Contents of the tables are not identical' , lu.assertItemsEquals, 'foo', 'bar' ) -- value mismatch
    end 

    function TestLuaUnitErrorMsg:test_assertError()
        assertFailureEquals('Expected an error when calling function but no error generated' , lu.assertError, function( v ) local y = v+1 end, 3 )
    end 

    function TestLuaUnitErrorMsg:test_assertErrorMsg()
        assertFailureEquals('No error generated when calling function but expected error: "bla bla bla"' , lu.assertErrorMsgEquals, 'bla bla bla', function( v ) local y = v+1 end, 3 )
        assertFailureEquals('No error generated when calling function but expected error containing: "bla bla bla"' , lu.assertErrorMsgContains, 'bla bla bla', function( v ) local y = v+1 end, 3 )
        assertFailureEquals('No error generated when calling function but expected error matching: "bla bla bla"' , lu.assertErrorMsgMatches, 'bla bla bla', function( v ) local y = v+1 end, 3 )

        assertFailureEquals('Exact error message expected: "bla bla bla"\nError message received: "toto xxx"\n' , lu.assertErrorMsgEquals, 'bla bla bla', function( v ) error('toto xxx',2) end, 3 )
        assertFailureEquals('Error message does not contain: "bla bla bla"\nError message received: "toto xxx"\n' , lu.assertErrorMsgContains, 'bla bla bla', function( v ) error('toto xxx',2) end, 3 )
        assertFailureEquals('Error message does not match: "bla bla bla"\nError message received: "toto xxx"\n' , lu.assertErrorMsgMatches, 'bla bla bla', function( v ) error('toto xxx',2) end, 3 )

    end 

    function TestLuaUnitErrorMsg:test_printTableWithRef()
        lu.PRINT_TABLE_REF_IN_ERROR_MSG = true
        assertFailureMatches( 'Received the not expected value: <table: 0?x?[%x]+> {1, 2}', lu.assertNotEquals, {1,2}, {1,2} )
        -- trigger multiline prettystr
        assertFailureMatches( 'Received the not expected value: <table: 0?x?[%x]+> {1, 2, 3, 4}', lu.assertNotEquals, {1,2,3,4}, {1,2,3,4} )
        assertFailureMatches( 'expected: false, actual: <table: 0?x?[%x]+> {}', lu.assertFalse, {})
        local v = {1,2}
        assertFailureMatches( 'Expected object and actual object are the same object: <table: 0?x?[%x]+> {1, 2}', lu.assertNotIs, v, v )
        assertFailureMatches('Contents of the tables are not identical:\nExpected: <table: 0?x?[%x]+> {one=2, two=3}\nActual: <table: 0?x?[%x]+> {1, 2}' , lu.assertItemsEquals, {1,2}, {one=2, two=3} )
        assertFailureMatches( 'expected: <table: 0?x?[%x]+> {1, 2, 3}\nactual: <table: 0?x?[%x]+> {3, 2, 1}', lu.assertEquals, {3,2,1}, {1,2,3} )
        -- trigger multiline prettystr
        assertFailureMatches( 'expected: <table: 0?x?[%x]+> {1, 2, 3, 4}\nactual: <table: 0?x?[%x]+> {3, 2, 1, 4}', lu.assertEquals, {3,2,1,4}, {1,2,3,4} )
        assertFailureMatches( 'expected: <table: 0?x?[%x]+> {one=1, two=2}\nactual: <table: 0?x?[%x]+> {3, 2, 1}', lu.assertEquals, {3,2,1}, {one=1,two=2} )
    end

------------------------------------------------------------------
--
--                       Execution Tests 
--
------------------------------------------------------------------

local executedTests

MyTestToto1 = {} --class
    function MyTestToto1:test1() table.insert( executedTests, "MyTestToto1:test1" ) end
    function MyTestToto1:testb() table.insert( executedTests, "MyTestToto1:testb" ) end
    function MyTestToto1:test3() table.insert( executedTests, "MyTestToto1:test3" ) end
    function MyTestToto1:testa() table.insert( executedTests, "MyTestToto1:testa" ) end
    function MyTestToto1:test2() table.insert( executedTests, "MyTestToto1:test2" ) end

MyTestToto2 = {} --class
    function MyTestToto2:test1() table.insert( executedTests, "MyTestToto2:test1" ) end

MyTestWithErrorsAndFailures = {} --class
    function MyTestWithErrorsAndFailures:testWithFailure1() lu.assertEquals(1, 2) end
    function MyTestWithErrorsAndFailures:testWithFailure2() lu.assertError( function() end ) end
    function MyTestWithErrorsAndFailures:testWithError1() error('some error') end
    function MyTestWithErrorsAndFailures:testOk() end

MyTestOk = {} --class
    function MyTestOk:testOk1() end
    function MyTestOk:testOk2() end

function MyTestFunction()
    table.insert( executedTests, "MyTestFunction" ) 
end

TestLuaUnitExecution = { __class__ = 'TestLuaUnitExecution' }

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
        local allTests = lu.LuaUnit.collectTests()
        lu.assertEquals( allTests, {"MyTestFunction", "MyTestOk", "MyTestToto1", "MyTestToto2","MyTestWithErrorsAndFailures"})
    end

    function TestLuaUnitExecution:test_MethodsAreExecutedInRightOrder()
        local runner = lu.LuaUnit.new()
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
        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByNames( { 'MyTestToto2', 'MyTestToto1', 'MyTestFunction' } )
        lu.assertEquals( #executedTests, 7 )
        lu.assertEquals( executedTests[1], "MyTestToto2:test1" )
        lu.assertEquals( executedTests[2], "MyTestToto1:test1" )
        lu.assertEquals( executedTests[7], "MyTestFunction" )
    end

    function TestLuaUnitExecution:testRunSomeTestByGlobalInstance( )
        lu.assertEquals( #executedTests, 0 )
        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'Toto', MyTestToto1 } }  )
        lu.assertEquals( #executedTests, 5 )

        lu.assertEquals( #runner.result.tests, 5 )
        lu.assertEquals( runner.result.tests[1].testName, "Toto.test1" )
        lu.assertEquals( runner.result.tests[5].testName, "Toto.testb" )
    end

    function TestLuaUnitExecution:testRunSomeTestByLocalInstance( )
        local MyLocalTestToto1 = {} --class
        function MyLocalTestToto1:test1() table.insert( executedTests, "MyLocalTestToto1:test1" ) end
        local MyLocalTestToto2 = {} --class
        function MyLocalTestToto2:test1() table.insert( executedTests, "MyLocalTestToto2:test1" ) end
        function MyLocalTestToto2:test2() table.insert( executedTests, "MyLocalTestToto2:test2" ) end
        local function MyLocalTestFunction() table.insert( executedTests, "MyLocalTestFunction" ) end
 
        lu.assertEquals( #executedTests, 0 )
        local runner = lu.LuaUnit.new()
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
        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        local ret = runner:runSuite( 'MyTestWithErrorsAndFailures' )
        lu.assertEquals(ret, 3)

        ret = runner:runSuite( 'MyTestToto1' )
        lu.assertEquals(ret, 0)
    end

    function TestLuaUnitExecution:testTestCountAndFailCount()
        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuite( 'MyTestWithErrorsAndFailures' )
        lu.assertEquals( runner.result.testCount, 4)
        lu.assertEquals( runner.result.notPassedCount, 3)
        lu.assertEquals( runner.result.failureCount, 2)
        lu.assertEquals( runner.result.errorCount, 1)

        runner:runSuite( 'MyTestToto1' )
        lu.assertEquals( runner.result.testCount, 5)
        lu.assertEquals( runner.result.notPassedCount, 0)
        lu.assertEquals( runner.result.failureCount, 0)
        lu.assertEquals( runner.result.errorCount, 0)
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

        local MyTestWithSetupTeardown3 = {}
            function MyTestWithSetupTeardown3:Setup()    table.insert( myExecutedTests, '3Setup' ) end
            function MyTestWithSetupTeardown3:test1()    table.insert( myExecutedTests, '3test1' ) end
            function MyTestWithSetupTeardown3:Teardown() table.insert( myExecutedTests, '3Teardown' )  end

        local MyTestWithSetupTeardown4 = {}
            function MyTestWithSetupTeardown4:setup()    table.insert( myExecutedTests, '4setup' ) end
            function MyTestWithSetupTeardown4:test1()    table.insert( myExecutedTests, '4test1' ) end
            function MyTestWithSetupTeardown4:teardown() table.insert( myExecutedTests, '4teardown' )  end

        local MyTestWithSetupTeardown5 = {}
            function MyTestWithSetupTeardown5:SetUp()    table.insert( myExecutedTests, '5SetUp' ) end
            function MyTestWithSetupTeardown5:test1()    table.insert( myExecutedTests, '5test1' ) end
            function MyTestWithSetupTeardown5:TearDown() table.insert( myExecutedTests, '5TearDown' )  end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupTeardown.test1', MyTestWithSetupTeardown } } )
        lu.assertEquals( runner.result.notPassedCount, 0 )
        lu.assertEquals( myExecutedTests[1], '1setUp' )   
        lu.assertEquals( myExecutedTests[2], '1test1')
        lu.assertEquals( myExecutedTests[3], '1tearDown')
        lu.assertEquals( #myExecutedTests, 3)

        myExecutedTests = {}
        runner:runSuiteByInstances( { 
            { 'MyTestWithSetupTeardown', MyTestWithSetupTeardown },
            { 'MyTestWithSetupTeardown2', MyTestWithSetupTeardown2 },
            { 'MyTestWithSetupTeardown3', MyTestWithSetupTeardown3 },
            { 'MyTestWithSetupTeardown4', MyTestWithSetupTeardown4 },
            { 'MyTestWithSetupTeardown5', MyTestWithSetupTeardown5 }
        } )
        lu.assertEquals( runner.result.notPassedCount, 0 )
        lu.assertEquals( myExecutedTests[1], '1setUp' )   
        lu.assertEquals( myExecutedTests[2], '1test1')
        lu.assertEquals( myExecutedTests[3], '1tearDown')
        lu.assertEquals( myExecutedTests[4], '1setUp' )   
        lu.assertEquals( myExecutedTests[5], '1test2')
        lu.assertEquals( myExecutedTests[6], '1tearDown')
        lu.assertEquals( myExecutedTests[7], '2setUp' )   
        lu.assertEquals( myExecutedTests[8], '2test1')
        lu.assertEquals( myExecutedTests[9], '2tearDown')
        lu.assertEquals( myExecutedTests[10], '3Setup')
        lu.assertEquals( myExecutedTests[11], '3test1')
        lu.assertEquals( myExecutedTests[12], '3Teardown')
        lu.assertEquals( myExecutedTests[13], '4setup')
        lu.assertEquals( myExecutedTests[14], '4test1')
        lu.assertEquals( myExecutedTests[15], '4teardown')
        lu.assertEquals( myExecutedTests[16], '5SetUp')
        lu.assertEquals( myExecutedTests[17], '5test1')
        lu.assertEquals( myExecutedTests[18], '5TearDown')
        lu.assertEquals( #myExecutedTests, 18)
    end

    function TestLuaUnitExecution:testWithSetupTeardownFailure1()
        local myExecutedTests = {}

        local MyTestWithSetupFailure = {}
            function MyTestWithSetupFailure:setUp()    table.insert( myExecutedTests, 'setUp' ) lu.assertEquals( 'b', 'c') end
            function MyTestWithSetupFailure:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupFailure:tearDown() table.insert( myExecutedTests, 'tearDown' )  end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupFailure', MyTestWithSetupFailure } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        lu.assertEquals( runner.result.failureCount, 1 )
        lu.assertEquals( runner.result.errorCount, 0 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'tearDown')
        lu.assertEquals( #myExecutedTests, 2)
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.FAIL  )
    end

    function TestLuaUnitExecution:testWithSetupTeardownFailure2()
        local myExecutedTests = {}

        local MyTestWithSetupFailure = {}
            function MyTestWithSetupFailure:setUp()    table.insert( myExecutedTests, 'setUp' ) end
            function MyTestWithSetupFailure:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupFailure:tearDown() table.insert( myExecutedTests, 'tearDown' ) lu.assertEquals( 'b', 'c')   end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupFailure', MyTestWithSetupFailure } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        lu.assertEquals( runner.result.failureCount, 1 )
        lu.assertEquals( runner.result.errorCount, 0 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'test1' )   
        lu.assertEquals( myExecutedTests[3], 'tearDown')
        lu.assertEquals( #myExecutedTests, 3)
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.FAIL  )
    end

    function TestLuaUnitExecution:testWithSetupTeardownFailure3()
        local myExecutedTests = {}

        local MyTestWithSetupFailure = {}
            function MyTestWithSetupFailure:setUp()    table.insert( myExecutedTests, 'setUp' ) lu.assertEquals( 'b', 'c') end
            function MyTestWithSetupFailure:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupFailure:tearDown() table.insert( myExecutedTests, 'tearDown' ) lu.assertEquals( 'b', 'c')   end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupFailure', MyTestWithSetupFailure } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        -- Note: in the future, we may want to report two failures for this
        lu.assertEquals( runner.result.failureCount, 1 )
        lu.assertEquals( runner.result.errorCount, 0 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'tearDown')
        lu.assertEquals( #myExecutedTests, 2)
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.FAIL  )
    end

    function TestLuaUnitExecution:testWithSetupTeardownFailure4()
        local myExecutedTests = {}

        local MyTestWithSetupFailure = {}
            function MyTestWithSetupFailure:setUp()    table.insert( myExecutedTests, 'setUp' ) lu.assertEquals( 'b', 'c') end
            function MyTestWithSetupFailure:test1()    table.insert( myExecutedTests, 'test1' ) lu.assertEquals( 'b', 'c')  end
            function MyTestWithSetupFailure:tearDown() table.insert( myExecutedTests, 'tearDown' ) lu.assertEquals( 'b', 'c')   end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupFailure', MyTestWithSetupFailure } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        -- Note: in the future, we may want to report two failures for this
        lu.assertEquals( runner.result.failureCount, 1 )
        lu.assertEquals( runner.result.errorCount, 0 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'tearDown')
        lu.assertEquals( #myExecutedTests, 2)
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.FAIL  )
    end

    function TestLuaUnitExecution:testWithSetupTeardownFailure5()
        local myExecutedTests = {}

        local MyTestWithSetupFailure = {}
            function MyTestWithSetupFailure:setUp()    table.insert( myExecutedTests, 'setUp' ) end
            function MyTestWithSetupFailure:test1()    table.insert( myExecutedTests, 'test1' ) lu.assertEquals( 'b', 'c')  end
            function MyTestWithSetupFailure:tearDown() table.insert( myExecutedTests, 'tearDown' ) lu.assertEquals( 'b', 'c')   end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupFailure', MyTestWithSetupFailure } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        -- Note: in the future, we may want to report two failures for this
        lu.assertEquals( runner.result.failureCount, 1 )
        lu.assertEquals( runner.result.errorCount, 0 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'test1' )   
        lu.assertEquals( myExecutedTests[3], 'tearDown')
        lu.assertEquals( #myExecutedTests, 3)
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.FAIL  )
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors1()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ) error('setup error') end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' )  end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        lu.assertEquals( runner.result.failureCount, 0 )
        lu.assertEquals( runner.result.errorCount, 1 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'tearDown')
        lu.assertEquals( #myExecutedTests, 2)
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.ERROR  )
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors2()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ) end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ) error('teardown error')   end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        lu.assertEquals( runner.result.failureCount, 0 )
        lu.assertEquals( runner.result.errorCount, 1 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'test1' )   
        lu.assertEquals( myExecutedTests[3], 'tearDown')
        lu.assertEquals( #myExecutedTests, 3)
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.ERROR  )
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors3()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ) error('setup error') end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ) error('teardown error')   end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        -- Note: in the future, we may want to report two errors for this
        lu.assertEquals( runner.result.failureCount, 0 )
        lu.assertEquals( runner.result.errorCount, 1 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'tearDown')
        lu.assertEquals( #myExecutedTests, 2)
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.ERROR  )
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors4()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ) error('setup error') end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) error('test error')  end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ) error('teardown error')   end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        -- Note: in the future, we may want to report two errors for this
        lu.assertEquals( runner.result.failureCount, 0 )
        lu.assertEquals( runner.result.errorCount, 1 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'tearDown')
        lu.assertEquals( #myExecutedTests, 2)
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.ERROR  )
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrors5()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ) end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) error('test error') end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ) error('teardown error')   end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        -- Note: in the future, we may want to report two errors for this
        lu.assertEquals( runner.result.failureCount, 0 )
        lu.assertEquals( runner.result.errorCount, 1 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'test1' )   
        lu.assertEquals( myExecutedTests[3], 'tearDown')
        lu.assertEquals( #myExecutedTests, 3)
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.ERROR  )
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrorsAndFailures1()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ) lu.assertEquals( 'a', 'b') end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ) error('teardown error')   end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        -- Note: in the future, we may want to report failure + error for this
        lu.assertEquals( runner.result.failureCount, 1 )
        lu.assertEquals( runner.result.errorCount, 0 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'tearDown')
        lu.assertEquals( #myExecutedTests, 2)
        -- The first error/failure set the whole test status
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.FAIL  )
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrorsAndFailures2()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ) error('setup error') end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ) lu.assertEquals( 'a', 'b')   end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        -- Note: in the future, we may want to report failure + error for this
        lu.assertEquals( runner.result.failureCount, 0 )
        lu.assertEquals( runner.result.errorCount, 1 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'tearDown')
        lu.assertEquals( #myExecutedTests, 2)
        -- The first error/failure set the whole test status
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.ERROR  )
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrorsAndFailures3()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ) end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) error('test error') end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ) lu.assertEquals( 'a', 'b')   end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        -- Note: in the future, we may want to report failure + error for this
        lu.assertEquals( runner.result.failureCount, 0 )
        lu.assertEquals( runner.result.errorCount, 1 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'test1' )   
        lu.assertEquals( myExecutedTests[3], 'tearDown')
        lu.assertEquals( #myExecutedTests, 3)
        -- The first error/failure set the whole test status
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.ERROR  )
    end

    function TestLuaUnitExecution:testWithSetupTeardownErrorsAndFailures4()
        local myExecutedTests = {}

        local MyTestWithSetupError = {}
            function MyTestWithSetupError:setUp()    table.insert( myExecutedTests, 'setUp' ) end
            function MyTestWithSetupError:test1()    table.insert( myExecutedTests, 'test1' ) lu.assertEquals( 'a', 'b') end
            function MyTestWithSetupError:tearDown() table.insert( myExecutedTests, 'tearDown' ) error('teardown error')   end

        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByInstances( { { 'MyTestWithSetupError', MyTestWithSetupError } } )
        lu.assertEquals( runner.result.notPassedCount, 1 )
        -- Note: in the future, we may want to report failure + error for this
        lu.assertEquals( runner.result.failureCount, 1 )
        lu.assertEquals( runner.result.errorCount, 0 )
        lu.assertEquals( runner.result.testCount, 1 )
        lu.assertEquals( myExecutedTests[1], 'setUp' )   
        lu.assertEquals( myExecutedTests[2], 'test1' )   
        lu.assertEquals( myExecutedTests[3], 'tearDown')
        lu.assertEquals( #myExecutedTests, 3)
        -- The first error/failure set the whole test status
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.FAIL  )
    end



    function TestLuaUnitExecution:testOutputInterface()
        local runner = lu.LuaUnit.new()
        runner.outputType = Mock
        runner:runSuite( 'MyTestWithErrorsAndFailures', 'MyTestOk' )
        local m = runner.output

        lu.assertEquals( m.calls[1][1], 'startSuite' )
        lu.assertEquals(#m.calls[1], 2 )

        lu.assertEquals( m.calls[2][1], 'startClass' )
        lu.assertEquals( m.calls[2][3], 'MyTestWithErrorsAndFailures' )
        lu.assertEquals(#m.calls[2], 3 )

        lu.assertEquals( m.calls[3][1], 'startTest' )
        lu.assertEquals( m.calls[3][3], 'MyTestWithErrorsAndFailures.testOk' )
        lu.assertEquals(#m.calls[3], 3 )

        lu.assertEquals( m.calls[4][1], 'endTest' )
        lu.assertEquals(#m.calls[4], 3 )
        lu.assertIsTable( m.calls[4][3] )
        lu.assertEquals( m.calls[4][3].status, lu.NodeStatus.PASS )

        lu.assertEquals( m.calls[5][1], 'startTest' )
        lu.assertEquals( m.calls[5][3], 'MyTestWithErrorsAndFailures.testWithError1' )
        lu.assertEquals(#m.calls[5], 3 )

        lu.assertEquals( m.calls[6][1], 'addStatus' )
        lu.assertEquals(#m.calls[6], 3 )

        lu.assertEquals( m.calls[7][1], 'endTest' )
        lu.assertEquals(#m.calls[7], 3 )
        lu.assertIsTable( m.calls[7][3] )
        lu.assertEquals( m.calls[7][3].status, lu.NodeStatus.ERROR )


        lu.assertEquals( m.calls[8][1], 'startTest' )
        lu.assertEquals( m.calls[8][3], 'MyTestWithErrorsAndFailures.testWithFailure1' )
        lu.assertEquals(#m.calls[8], 3 )

        lu.assertEquals( m.calls[9][1], 'addStatus' )
        lu.assertEquals(#m.calls[9], 3 )

        lu.assertEquals( m.calls[10][1], 'endTest' )
        lu.assertEquals(#m.calls[10], 3 )
        lu.assertIsTable( m.calls[10][3] )
        lu.assertEquals( m.calls[10][3].status, lu.NodeStatus.FAIL )

        lu.assertEquals( m.calls[11][1], 'startTest' )
        lu.assertEquals( m.calls[11][3], 'MyTestWithErrorsAndFailures.testWithFailure2' )
        lu.assertEquals(#m.calls[11], 3 )

        lu.assertEquals( m.calls[12][1], 'addStatus' )
        lu.assertEquals(#m.calls[12], 3 )

        lu.assertEquals( m.calls[13][1], 'endTest' )
        lu.assertEquals(#m.calls[13], 3 )
        lu.assertIsTable(m.calls[13][3] )
        lu.assertEquals( m.calls[13][3].status, lu.NodeStatus.FAIL )

        lu.assertEquals( m.calls[14][1], 'endClass' )
        lu.assertEquals(#m.calls[14], 2 )

        lu.assertEquals( m.calls[15][1], 'startClass' )
        lu.assertEquals( m.calls[15][3], 'MyTestOk' )
        lu.assertEquals(#m.calls[15], 3 )

        lu.assertEquals( m.calls[16][1], 'startTest' )
        lu.assertEquals( m.calls[16][3], 'MyTestOk.testOk1' )
        lu.assertEquals(#m.calls[16], 3 )

        lu.assertEquals( m.calls[17][1], 'endTest' )
        lu.assertEquals(#m.calls[17], 3 )
        lu.assertIsTable( m.calls[17][3] )
        lu.assertEquals( m.calls[17][3].status, lu.NodeStatus.PASS )

        lu.assertEquals( m.calls[18][1], 'startTest' )
        lu.assertEquals( m.calls[18][3], 'MyTestOk.testOk2' )
        lu.assertEquals(#m.calls[18], 3 )

        lu.assertEquals( m.calls[19][1], 'endTest' )
        lu.assertEquals(#m.calls[19], 3 )
        lu.assertIsTable( m.calls[19][3] )
        lu.assertEquals( m.calls[19][3].status, lu.NodeStatus.PASS )

        lu.assertEquals( m.calls[20][1], 'endClass' )
        lu.assertEquals(#m.calls[20], 2 )

        lu.assertEquals( m.calls[21][1], 'endSuite' )
        lu.assertEquals(#m.calls[21], 2 )

        lu.assertEquals( m.calls[22], nil )

    end

    function TestLuaUnitExecution:testInvocation()

        local runner = lu.LuaUnit.new()

        -- test alternative "object" syntax for run(), passing self
        runner:run('--output', 'nil', 'MyTestOk')
        -- select class instance by name
        runner.run('--output', 'nil', 'MyTestOk.testOk2')

        -- check error handling
        lu.assertErrorMsgContains('No such name in global space',
                                  runner.runSuite, runner, 'foobar')
        lu.assertErrorMsgContains('Name must match a function or a table',
                                  runner.runSuite, runner, '_VERSION')
        lu.assertErrorMsgContains('No such name in global space',
                                  runner.runSuite, runner, 'foo.bar')
        lu.assertErrorMsgContains('must be a function, not',
                                  runner.runSuite, runner, '_G._VERSION')
        lu.assertErrorMsgContains('Could not find method in class',
                                  runner.runSuite, runner, 'MyTestOk.foobar')
        lu.assertErrorMsgContains('Instance must be a table or a function',
                                  runner.expandClasses, {{'foobar', 'INVALID'}})
        lu.assertErrorMsgContains('Could not find method in class',
                                  runner.expandClasses, {{'MyTestOk.foobar', {}}})
    end

    function TestLuaUnitExecution:test_filterWithPattern()

        local runner = lu.LuaUnit.new()
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

TestLuaUnitResults = { __class__ = 'TestLuaUnitResults' }

    function TestLuaUnitResults:tearDown()
        executedTests = {}
        lu.LuaUnit.isTestName = lu.LuaUnit.isTestNameOld
    end

    function TestLuaUnitResults:setUp()
        executedTests = {}
        lu.LuaUnit.isTestNameOld = lu.LuaUnit.isTestName
        lu.LuaUnit.isTestName = function( s ) return (string.sub(s,1,6) == 'MyTest') end
    end

    function TestLuaUnitResults:test_statusLine()
        -- full success
        local r = {runCount=5, duration=0.17, passedCount=5, notPassedCount=0, failureCount=0, errorCount=0, nonSelectedCount=0}
        lu.assertEquals( lu.LuaUnit.statusLine(r), 'Ran 5 tests in 0.170 seconds, 5 successes, 0 failures')

        -- 1 failure, nothing more displayed
        r = {runCount=5, duration=0.17, passedCount=4, notPassedCount=1, failureCount=1, errorCount=0, nonSelectedCount=0}
        lu.assertEquals( lu.LuaUnit.statusLine(r), 'Ran 5 tests in 0.170 seconds, 4 successes, 1 failure')

        -- 1 error, no failure displayed
        r = {runCount=5, duration=0.17, passedCount=4, notPassedCount=1, failureCount=0, errorCount=1, nonSelectedCount=0}
        lu.assertEquals( lu.LuaUnit.statusLine(r), 'Ran 5 tests in 0.170 seconds, 4 successes, 1 error')

        -- 1 error, 1 failure 
        r = {runCount=5, duration=0.17, passedCount=3, notPassedCount=2, failureCount=1, errorCount=1, nonSelectedCount=0}
        lu.assertEquals( lu.LuaUnit.statusLine(r), 'Ran 5 tests in 0.170 seconds, 3 successes, 1 failure, 1 error')

        -- 1 error, 1 failure, 1 non selected
        r = {runCount=5, duration=0.17, passedCount=3, notPassedCount=2, failureCount=1, errorCount=1, nonSelectedCount=1}
        lu.assertEquals( lu.LuaUnit.statusLine(r), 'Ran 5 tests in 0.170 seconds, 3 successes, 1 failure, 1 error, 1 non-selected')

        -- full success, 1 non selected
        r = {runCount=5, duration=0.17, passedCount=5, notPassedCount=0, failureCount=0, errorCount=0, nonSelectedCount=1}
        lu.assertEquals( lu.LuaUnit.statusLine(r), 'Ran 5 tests in 0.170 seconds, 5 successes, 0 failures, 1 non-selected')
    end

    function TestLuaUnitResults:test_nodeStatus()
        local es = lu.NodeStatus.new()
        lu.assertEquals( es.status, lu.NodeStatus.PASS )
        lu.assertTrue( es:isPassed() )
        lu.assertNil( es.msg )
        lu.assertNil( es.stackTrace )
        lu.assertStrContains( es:statusXML(), "<passed" )

        es:fail( 'msgToto', 'stackTraceToto' )
        lu.assertEquals( es.status, lu.NodeStatus.FAIL )
        lu.assertTrue( es:isNotPassed() )
        lu.assertTrue( es:isFailure() )
        lu.assertFalse( es:isError() )
        lu.assertEquals( es.msg, 'msgToto' )
        lu.assertEquals( es.stackTrace, 'stackTraceToto' )
        lu.assertStrContains( es:statusXML(), "<failure" )

        local es2 = lu.NodeStatus.new()
        lu.assertEquals( es2.status, lu.NodeStatus.PASS )
        lu.assertNil( es2.msg )
        lu.assertNil( es2.stackTrace )

        es:error( 'msgToto2', 'stackTraceToto2' )
        lu.assertEquals( es.status, lu.NodeStatus.ERROR )
        lu.assertTrue( es:isNotPassed() )
        lu.assertFalse( es:isFailure() )
        lu.assertTrue( es:isError() )
        lu.assertEquals( es.msg, 'msgToto2' )
        lu.assertEquals( es.stackTrace, 'stackTraceToto2' )
        lu.assertStrContains( es:statusXML(), "<error" )

        es:pass()
        lu.assertEquals( es.status, lu.NodeStatus.PASS )
        lu.assertTrue( es:isPassed() )
        lu.assertFalse( es:isNotPassed() )
        lu.assertFalse( es:isFailure() )
        lu.assertFalse( es:isError() )
        lu.assertNil( es.msg )
        lu.assertNil( es.stackTrace )

    end

    function TestLuaUnitResults:test_runSuiteOk()
        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuiteByNames( { 'MyTestToto2', 'MyTestToto1', 'MyTestFunction' } )
        lu.assertEquals( #runner.result.tests, 7 )
        lu.assertEquals( #runner.result.notPassed, 0 )

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
        local runner = lu.LuaUnit.new()
        runner:setOutputType( "NIL" )
        runner:runSuite( 'MyTestWithErrorsAndFailures' )

        lu.assertEquals( #runner.result.tests, 4 )
        lu.assertEquals( #runner.result.notPassed, 3 )

        lu.assertEquals( runner.result.tests[1].number, 1 )
        lu.assertEquals( runner.result.tests[1].testName, "MyTestWithErrorsAndFailures.testOk" )
        lu.assertEquals( runner.result.tests[1].className, 'MyTestWithErrorsAndFailures' )
        lu.assertEquals( runner.result.tests[1].status, lu.NodeStatus.PASS )
        lu.assertIsNumber( runner.result.tests[1].duration )
        lu.assertIsNil( runner.result.tests[1].msg )
        lu.assertIsNil( runner.result.tests[1].stackTrace )

        lu.assertEquals( runner.result.tests[2].testName, 'MyTestWithErrorsAndFailures.testWithError1' )
        lu.assertEquals( runner.result.tests[2].className, 'MyTestWithErrorsAndFailures' )
        lu.assertEquals( runner.result.tests[2].status, lu.NodeStatus.ERROR )
        lu.assertIsString( runner.result.tests[2].msg )
        lu.assertIsString( runner.result.tests[2].stackTrace )

        lu.assertEquals( runner.result.tests[3].testName, 'MyTestWithErrorsAndFailures.testWithFailure1' )
        lu.assertEquals( runner.result.tests[3].className, 'MyTestWithErrorsAndFailures' )
        lu.assertEquals( runner.result.tests[3].status, lu.NodeStatus.FAIL )
        lu.assertIsString( runner.result.tests[3].msg )
        lu.assertIsString( runner.result.tests[3].stackTrace )

        lu.assertEquals( runner.result.tests[4].testName, 'MyTestWithErrorsAndFailures.testWithFailure2' )
        lu.assertEquals( runner.result.tests[4].className, 'MyTestWithErrorsAndFailures' )
        lu.assertEquals( runner.result.tests[4].status, lu.NodeStatus.FAIL )
        lu.assertIsString( runner.result.tests[4].msg )
        lu.assertIsString( runner.result.tests[4].stackTrace )

        lu.assertEquals( runner.result.notPassed[1].testName, 'MyTestWithErrorsAndFailures.testWithError1' )
        lu.assertEquals( runner.result.notPassed[1].className, 'MyTestWithErrorsAndFailures' )
        lu.assertEquals( runner.result.notPassed[1].status, lu.NodeStatus.ERROR )
        lu.assertIsString( runner.result.notPassed[1].msg )
        lu.assertIsString( runner.result.notPassed[1].stackTrace )

        lu.assertEquals( runner.result.notPassed[2].testName, 'MyTestWithErrorsAndFailures.testWithFailure1' )
        lu.assertEquals( runner.result.notPassed[2].className, 'MyTestWithErrorsAndFailures' )
        lu.assertEquals( runner.result.notPassed[2].status, lu.NodeStatus.FAIL )
        lu.assertIsString( runner.result.notPassed[2].msg )
        lu.assertIsString( runner.result.notPassed[2].stackTrace )

        lu.assertEquals( runner.result.notPassed[3].testName, 'MyTestWithErrorsAndFailures.testWithFailure2' )
        lu.assertEquals( runner.result.notPassed[3].className, 'MyTestWithErrorsAndFailures' )
        lu.assertEquals( runner.result.notPassed[3].status, lu.NodeStatus.FAIL )
        lu.assertIsString( runner.result.notPassed[3].msg )
        lu.assertIsString( runner.result.notPassed[3].stackTrace )

    end

    function TestLuaUnitResults:test_resultsWhileTestInProgress()
        local MyMocker = { __class__ = "MyMocker" }
        -- MyMocker is an outputter that creates a customized "Mock" instance
        function MyMocker.new(runner)
            local t = Mock.new(runner)
            function t:startTest( testName )
                local node = self.result.currentNode
                if node.number == 1 then
                    lu.assertEquals( node.number, 1 )
                    lu.assertEquals( node.testName, 'MyTestWithErrorsAndFailures.testOk' )
                    lu.assertEquals( node.className, 'MyTestWithErrorsAndFailures' )
                    lu.assertEquals( node.status, lu.NodeStatus.PASS )
                elseif node.number == 2 then
                    lu.assertEquals( node.number, 2 )
                    lu.assertEquals( node.testName, 'MyTestWithErrorsAndFailures.testWithError1' )
                    lu.assertEquals( node.className, 'MyTestWithErrorsAndFailures' )
                    lu.assertEquals( node.status, lu.NodeStatus.PASS )
                end
            end
            function t:endTest( node )
                lu.assertEquals( node, self.result.currentNode )
                if node.number == 1 then
                    lu.assertEquals( node.status, lu.NodeStatus.PASS )
                elseif node.number == 2 then
                    lu.assertEquals( node.status, lu.NodeStatus.ERROR )
                end
            end
            return t
        end

        local runner = lu.LuaUnit.new()
        runner.outputType = MyMocker
        runner:runSuite( 'MyTestWithErrorsAndFailures' )

        local m = runner.output
        lu.assertEquals( m.calls[1][1], 'startSuite' )
        lu.assertEquals(#m.calls[1], 2 )
    end

-- To execute me , use: lua run_unit_tests.lua
