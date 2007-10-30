
require('luaunit')

TestToto = {} --class

    function TestToto:setUp()
        -- set up tests
		self.a = 1
		self.s = 'hop' 
    end

    function TestToto:test1_withFailure()
		print( "some stuff test 1" )
        assertEquals( self.a , 1 )
        -- will fail
        assertEquals( self.a , 2 )
        assertEquals( self.a , 2 )
    end

    function TestToto:test2_withFailure()
		print( "some stuff test 2" )
        assertEquals( self.a , 1 )
        assertEquals( self.s , 'hop' )
        -- will fail
        assertEquals( self.s , 'bof' )
        assertEquals( self.s , 'bof' )
    end

    function TestToto:test3()
		print( "some stuff test 3" )
        assertEquals( self.a , 1 )
        assertEquals( self.s , 'hop' )
        assertEquals( type(self.a), 'number' )
    end
-- class TestToto

TestTiti = {} --class
    function TestTiti:setUp()
        -- set up tests
		self.a = 1
		self.s = 'hop' 
        print( 'TestTiti:setUp' )
    end

	function TestTiti:tearDown()
		-- some tearDown() code if necessary
        print( 'TestTiti:tearDown' )
	end

    function TestTiti:test1_withFailure()
		print( "some stuff test 1" )
        assertEquals( self.a , 1 )
        -- will fail
        assertEquals( self.a , 2 )
        assertEquals( self.a , 2 )
    end

    function TestTiti:test2_withFailure()
		print( "some stuff test 2" )
        assertEquals( self.a , 1 )
        assertEquals( self.s , 'hop' )
        -- will fail
        assertEquals( self.s , 'bof' )
        assertEquals( self.s , 'bof' )
    end

    function TestTiti:test3()
		print( "some stuff test 3" )
        assertEquals( self.a , 1 )
        assertEquals( self.s , 'hop' )
    end
-- class TestTiti

-- simple test functions that were written previously can be integrated
-- in luaunit too
function test1_withFailure()
    assert( 1 == 1)
    -- will fail
    assert( 1 == 2)
end

function test2_withFailure()
    assert( 'a' == 'a')
    -- will fail
    assert( 'a' == 'b')
end

function test3()
    assert( 1 == 1)
    assert( 'a' == 'a')
end

TestFunctions = wrapFunctions( 'test1', 'test2', 'test3' )

-- LuaUnit:run( 'test2_withFailure' )  -- run only one test function
-- LuaUnit:run( 'test1_withFailure' )
-- LuaUnit:run( 'TestToto' ) -- run only on test class
-- LuaUnit:run( 'TestTiti:test3') -- run only one test method of a test class
LuaUnit:run() -- run all tests
