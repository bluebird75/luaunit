lu = require('luaunit')

--[[ Test used by functional tests ]]
TestSomething = {} --class

    function TestSomething:testSuccess1()
        lu.assertEquals( 1+1, 2 )
    end

    function TestSomething:testSuccess2()
        lu.assertEquals( 1+2, 3 )
    end

    function TestSomething:testFail1()
        lu.assertEquals( 1+1, 0 )
    end

    function TestSomething:testFail2()
        lu.assertEquals( 1+2, 0 )
    end

    function TestSomething:testErr1()
        v = 1 + { 1,2 }
    end

    function TestSomething:testErr2()
        v = 1 + { 1,2 }
    end

TestAnotherThing = {} --class

    function TestAnotherThing:testSuccess1()
        lu.assertEquals( 1+1, 2 )
    end

    function TestAnotherThing:testSuccess2()
        lu.assertEquals( 1+2, 3 )
    end

    function TestAnotherThing:testFail1()
        lu.assertEquals( 1+1, 0 )
    end

    function TestAnotherThing:testFail2()
        lu.assertEquals( 1+2, 0 )
    end

    function TestAnotherThing:testErr1()
        v = 1 + { 1,2 }
    end

    function TestAnotherThing:testErr2()
        v = 1 + { 1,2 }
    end


function testFuncSuccess1()
    lu.assertEquals( 1+1, 2 )
end

function testFuncFail1()
    lu.assertEquals( 1+2, 0 )
end

function testFuncErr1()
    v = 1 + { 1,2 }
end

runner = lu.LuaUnit.new()
runner:setOutputType("text")
os.exit( runner:runSuite() )
