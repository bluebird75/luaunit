local lu = require('luaunit')

TestAddition = lu.parameterizedTests(function()
    return {
        zero = {0, 0, 0},
        mixed = {-2, 3, 1}
    }
end, function(self, left, right, expected)
    lu.assertTrue(self.ready)
    lu.assertEquals(left + right, expected)
end)

function TestAddition:setUp()
    self.ready = true
end

function TestAddition:tearDown()
    self.ready = nil
end

os.exit(lu.LuaUnit.run())
