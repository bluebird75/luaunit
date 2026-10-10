local lu = require('luaunit')
local suiteReady = false
local completedTests = 0

function setupSuite()
    suiteReady = true
end

function teardownSuite()
    lu.assertEquals(completedTests, 2)
    suiteReady = false
end

TestExample = {}

function TestExample:setupClass()
    lu.assertTrue(suiteReady)
    self.shared = { count = 0 }
end

function TestExample:setUp()
    self.value = 0
end

function TestExample:testFirst()
    lu.assertEquals(self.value, 0)
    self.value = 1
    self.shared.count = self.shared.count + 1
end

function TestExample:testSecond()
    lu.assertEquals(self.value, 0)
    self.value = 2
    self.shared.count = self.shared.count + 1
end

function TestExample:tearDown()
    completedTests = completedTests + 1
    self.value = nil
end

function TestExample:teardownClass()
    lu.assertEquals(self.shared.count, 2)
    self.shared = nil
end

os.exit(lu.LuaUnit.run())
