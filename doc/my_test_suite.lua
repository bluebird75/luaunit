
luaunit = require('luaunit')

function add(v1,v2)
    -- add positive numbers
    -- return 0 if any of the numbers are 0
    -- error if any of the two numbers are negative
    if v1 < 0 or v2 < 0 then
        error('Can only add positive or null numbers, received '..v1..' and '..v2)
    end
    if v1 == 0 or v2 == 0 then
        return 0
    end
    return v1+v2
end

function adder(v)
    -- return a function that adds v to its argument using add
    function closure( x ) return x+v end
    return closure
end

function div(v1,v2)
    -- divide positive numbers
    -- return 0 if any of the numbers are 0
    -- error if any of the two numbers are negative
    if v1 < 0 or v2 < 0 then
        error('Can only divide positive or null numbers, received '..v1..' and '..v2)
    end
    if v1 == 0 or v2 == 0 then
        return 0
    end
    return v1/v2
end



TestAdd = {}
    function TestAdd:testAddPositive()
        luaunit.assertEquals(add(1,1),2)
    end

    function TestAdd:testAddZero()
        luaunit.assertEquals(add(1,0),0)
        luaunit.assertEquals(add(0,5),0)
        luaunit.assertEquals(add(0,0),0)
    end

    function TestAdd:testAddError()
        luaunit.assertErrorMsgContains('Can only add positive or null numbers, received 2 and -3', add, 2, -3)
    end

    function TestAdd:testAdder()
        f = adder(3)
        luaunit.assertIsFunction( f )
        luaunit.assertEquals( f(2), 5 )
    end
-- end of table TestAdd

TestDiv = {}
    function TestDiv:testDivPositive()
        luaunit.assertEquals(div(4,2),2)
    end

    function TestDiv:testDivZero()
        luaunit.assertEquals(div(4,0),0)
        luaunit.assertEquals(div(0,5),0)
        luaunit.assertEquals(div(0,0),0)
    end

    function TestDiv:testDivError()
        luaunit.assertErrorMsgContains('Can only divide positive or null numbers, received 2 and -3', div, 2, -3)
    end

--[[
TestLogger = {}
    function TestLogger:setUp()
        -- define the fname to use for logging
        self.fname = 'mytmplog.log'
        -- make sure the file does not already exists
        os.remove(self.fname)
    end

    function TestLogger:testLoggerCreatesFile()
        initLog(self.fname)
        log('toto')
        f = io.open(self.fname, 'r')
        luaunit.assertNotNil( f )
        f:close()
    end

    function TestLogger:tearDown()
        self.fname = 'mytmplog.log'
        -- cleanup our log file after all tests
        os.remove(self.fname)
    end

-- end of table TestDiv
]]

os.exit(luaunit.LuaUnit.run())