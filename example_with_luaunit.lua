
require('luaunit')

TestToto = {} --class

    function TestToto:setUp()
        -- set up tests
        self.a = 1
        self.s = 'hop' 
        self.t1 = {1,2,3}
        self.t2 = {one=1,two=2,three=3}
        self.t3 = {1,2,three=3}
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

    function TestToto:test4()
        print( "some stuff test 4" )
        assertNotEquals( self.a , 1 )
    end

    function TestToto:test5()
        print( "some stuff test 5" )
        assertTrue( self.a )
        assertFalse( self.a )
    end

    function TestToto:test6()
        print( "some stuff test 6" )
        assertTrue( false )
    end

    function TestToto:test7()
        -- assertEquals( {1,2}, self.t1 )
        -- assertEquals( {1,2}, self.t2 )
        assertEquals( {1,2}, self.t3 )
    end

    function TestToto:test8a()
        -- failure occurs in a submethod
        self:funcWithError()
    end

    function TestToto:test8b()
        -- failure occurs in a submethod
        self:funcWithFuncWithError()
    end

    function TestToto:funcWithFuncWithError()
        self:funcWithError()
    end

    function TestToto:funcWithError()
        error('Bouhouhoum error!')
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

lu = LuaUnit.new()
lu:setOutputType("tap")
os.exit( lu:runSuite() )
