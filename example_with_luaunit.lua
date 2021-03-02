#!/usr/bin/env lua


local lu = require('luaunit')

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
        -- print( "some stuff test 1" )
        lu.assertEquals( self.a , 1 )
        -- will fail
        lu.assertEquals( self.a , 2 )
        lu.assertEquals( self.a , 2 )
    end

    function TestToto:test2_withFailure()
        -- print( "some stuff test 2" )
        lu.assertEquals( self.a , 1 )
        lu.assertEquals( self.s , 'hop' )
        -- will fail
        lu.assertEquals( self.s , 'bof' )
        lu.assertEquals( self.s , 'bof' )
    end

    function TestToto:test3()
        -- print( "some stuff test 3" )
        lu.assertEquals( self.a , 1 )
        lu.assertEquals( self.s , 'hop' )
        lu.assertEquals( type(self.a), 'number' )
    end

    function TestToto:test4()
        -- print( "some stuff test 4" )
        lu.assertNotEquals( self.a , 1 )
    end

    function TestToto:test5()
        -- print( "some stuff test 5" )
        lu.assertEvalToTrue( self.a )
        lu.assertEvalToFalse( self.a ) -- will trigger the failure
    end

    function TestToto:test6()
        -- print( "some stuff test 6" )
        lu.assertTrue( true )
        lu.assertFalse( false )
        lu.assertEvalToFalse( nil )
        lu.assertFalse( nil ) -- trigger the failure assertFalse is strict
    end

    function TestToto:test7()
        -- assertEquals( {1,2}, self.t1 )
        -- assertEquals( {1,2}, self.t2 )
        lu.assertEquals( {1,2}, self.t3 )
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

    function TestToto:test_skipped()
        local test_conditions_are_met = false
        lu.skipIf( not test_conditions_are_met, "Test is skipped because ..." )
    end


-- class TestTiti

TestTiti = {} --class
    function TestTiti:setUp()
        -- set up tests
        self.a = 1
        self.s = 'hop' 
        -- print( 'TestTiti:setUp' )
    end

    function TestTiti:tearDown()
        -- some tearDown() code if necessary
        -- print( 'TestTiti:tearDown' )
    end

    function TestTiti:test1_withFailure()
        -- print( "some stuff test 1" )
        lu.assertEquals( self.a , 1 )
        -- will fail
        lu.assertEquals( self.a , 2 )
        lu.assertEquals( self.a , 2 )
    end

    function TestTiti:test2_withFailure()
        -- print( "some stuff test 2" )
        lu.assertEquals( self.a , 1 )
        lu.assertEquals( self.s , 'hop' )
        -- will fail
        lu.assertEquals( self.s , 'bof' )
        lu.assertEquals( self.s , 'bof' )
    end

    function TestTiti:test3()
        -- print( "some stuff test 3" )
        lu.assertEquals( self.a , 1 )
        lu.assertEquals( self.s , 'hop' )
    end
-- class TestTiti

-- simple test functions that were written previously can be integrated
-- in luaunit too
function test1_withAssertionError()
    assert( 1 == 1)
    -- will fail
    assert( 1 == 2)
end

function test2_withAssertionError()
    assert( 'a' == 'a')
    -- will fail
    assert( 'a' == 'b')
end

function test3()
    assert( 1 == 1)
    assert( 'a' == 'a')
end

local runner = lu.LuaUnit.new()
runner:setOutputType("text")
os.exit( runner:runSuite() )
