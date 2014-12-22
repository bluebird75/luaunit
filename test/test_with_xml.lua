
require('luaunit')

TestFailuresWithXml = {} --class

    TestFailuresWithXml.__class__ = 'TestFailuresWithXml'

    function TestFailuresWithXml:test_failure_with_simple_xml()
        assertEquals( '<toto>ti"ti</toto>', 'got it' )
    end

    function TestFailuresWithXml:test_failure_with_cdata_xml()
        assertEquals( 'cdata does not like ]]>', 'got it' )
    end

LuaUnit.verbosity = 2
os.exit( LuaUnit.run() )
