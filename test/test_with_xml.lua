
local lu = require('luaunit')

TestFailuresWithXml = {} --class

    TestFailuresWithXml.__class__ = 'TestFailuresWithXml'

    function TestFailuresWithXml:test_failure_with_simple_xml()
        lu.assertEquals( '<toto>ti"ti</toto>', 'got it' )
    end

    function TestFailuresWithXml:test_failure_with_cdata_xml()
        lu.assertEquals( 'cdata does not like ]]>', 'got it' )
    end

function TestThatLastsALongTime()
	local start = os.clock()
	while os.clock() - start < 1.1 do
	end
end

lu.LuaUnit.verbosity = 2
os.exit( lu.LuaUnit.run() )
