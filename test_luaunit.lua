-- auto-test for luaunit. This is a bit tricky since the test uses the
-- features that it tests

require('luaunit')

TestLuaUnit = {} --class
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

-- LuaUnit:run('TestLuaBinding:test_setline') -- will execute only one test
-- LuaUnit:run('TestLuaBinding') -- will execute only one class of test
-- LuaUnit.result.verbosity = 0
LuaUnit:run() -- will execute all tests

