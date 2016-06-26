local lu = require('luaunit')

--[[ Test used by functional tests ]]
TestSomething = {} --class

    function TestSomething:test1_Success1()
        lu.assertEquals( 1+1, 2 )
    end

    function TestSomething:test1_Success2()
        lu.assertEquals( 1+2, 3 )
    end

    function TestSomething:test2_Fail1()
        lu.assertEquals( 1+1, 0 )
    end

    function TestSomething:test2_Fail2()
        lu.assertEquals( 1+2, 0 )
    end

    function TestSomething:test3_Err1()
        local v = 1 + { 1,2 }
    end

    function TestSomething:test3_Err2()
        local v = 1 + { 1,2 }
    end

TestAnotherThing = {} --class

    function TestAnotherThing:test1_Success1()
        lu.assertEquals( 1+1, 2 )
    end

    function TestAnotherThing:test1_Success2()
        lu.assertEquals( 1+2, 3 )
    end

    function TestAnotherThing:test2_Err1()
        local v = 1 + { 1,2 }
    end

    function TestAnotherThing:test2_Err2()
        local v = 1 + { 1,2 }
    end

    function TestAnotherThing:test3_Fail1()
        lu.assertEquals( 1+1, 0 )
    end

    function TestAnotherThing:test3_Fail2()
        lu.assertEquals( 1+2, 0 )
    end


function testFuncSuccess1()
    lu.assertEquals( 1+1, 2 )
end

function testFuncFail1()
    lu.assertEquals( 1+2, 0 )
end

function testFuncErr1()
    local v = 1 + { 1,2 }
end

local runner = lu.LuaUnit.new()
runner:setOutputType("text")
os.exit( runner:runSuite() )
