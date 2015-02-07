
require('luaunit')

TestFailuresWithXml = {} --class

    TestFailuresWithXml.__class__ = 'TestFailuresWithXml'

    function TestFailuresWithXml:test_failure_with_simple_xml()
        assertEquals( '<toto>ti"ti</toto>', 'got it' )
    end

    function TestFailuresWithXml:test_failure_with_cdata_xml()
        assertEquals( 'cdata does not like ]]>', 'got it' )
    end

function TestThatLastsALongTime()
	local start = os.clock()
	while os.clock() - start < 1.1 do
	end
end

LuaUnit.verbosity = 2
os.exit( LuaUnit.run() )
