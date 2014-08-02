--[[ 
        luaunit.lua

Description: A unit testing framework
Homepage: https://github.com/bluebird75/luaunit
Initial author: Ryu, Gwang (http://www.gpgstudy.com/gpgiki/LuaUnit)
Lot of improvements by Philippe Fremy <phil@freehackers.org>
License: BSD License, see LICENSE.txt
]]--

argv = arg

--[[ Some people like assertEquals( actual, expected ) and some people prefer 
assertEquals( expected, actual ).
]]--
ORDER_ACTUAL_EXPECTED = true

VERBOSITY_DEFAULT = 10
VERBOSITY_LOW     = 1
VERBOSITY_QUIET   = 0
VERBOSITY_VERBOSE = 20 

----------------------------------------------------------------
--
--                 general utility functions
--
----------------------------------------------------------------

function __genSortedIndex( t )
    local sortedIndexStr = {}
    local sortedIndexInt = {}
    local sortedIndex = {}
    for key,_ in pairs(t) do
        if type(key) == 'string' then
            table.insert( sortedIndexStr, key )
        else
            table.insert( sortedIndexInt, key )
        end
    end
    table.sort( sortedIndexInt )
    table.sort( sortedIndexStr )
    for _,value in ipairs(sortedIndexInt) do
        table.insert( sortedIndex, value )
    end
    for _,value in ipairs(sortedIndexStr) do
        table.insert( sortedIndex, value )
    end
    return sortedIndex
end

function sortedNext(t, state)
    -- Equivalent of the next() function of table iteration, but returns the
    -- keys in the alphabetic order. We use a temporary sorted key table that
    -- is stored in the table being iterated.

    -- the algorithm cost is suboptimal. We iterate everytime through
    -- the sorted index to fetch the next key

    --print("sortedNext: state = "..tostring(state) )
    local key
    if state == nil then
        -- the first time, generate the index
        t.__sortedIndex = nil
        t.__sortedIndex = __genSortedIndex( t )
        key = t.__sortedIndex[1]
        return key, t[key]
    end
    -- fetch the next value
    key = nil
    for i = 1,#t.__sortedIndex do
        if t.__sortedIndex[i] == state then
            key = t.__sortedIndex[i+1]
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__sortedIndex = nil
    return
end

function sortedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in sorted order. This works only if the key types are all the same
    return sortedNext, t, nil
end

function strsplit(delimiter, text)
-- Split text into a list consisting of the strings in text,
-- separated by strings matching delimiter (which may be a pattern). 
-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
    local list = {}
    local pos = 1
    if string.find("", delimiter, 1) then -- this would result in endless loops
        error("delimiter matches empty string!")
    end
    while 1 do
        local first, last = string.find(text, delimiter, pos)
        if first then -- found?
            table.insert(list, string.sub(text, pos, first-1))
            pos = last+1
        else
            table.insert(list, string.sub(text, pos))
            break
        end
    end
    return list
end


function prefixString( prefix, s )
    -- Prefix all the lines of s with prefix
    local t, s2
    t = strsplit('\n', s)
    s2 = prefix..table.concat(t, '\n'..prefix)
    return s2
end

function table.keytostring(k)
    -- like prettystr but do not enclose with "" if the string is just alphanumerical
    -- this is better for displaying table keys who are often simple strings
    if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
        return k
    else
        return prettystr(k)
    end
end

function table.tostring( tbl )
    local result, done = {}, {}
    for k, v in ipairs( tbl ) do
        table.insert( result, prettystr( v ) )
        done[ k ] = true
    end

    for k, v in sortedPairs( tbl ) do
        if not done[ k ] then
            table.insert( result,
                table.keytostring( k ) .. "=" .. prettystr( v, true ) )
        end
    end
    return "{" .. table.concat( result, "," ) .. "}"
end

function prettystr( v, keeponeline )
    --[[ Better string conversion, to display nice variable content:
    For strings, if keeponeline is set to true, string is displayed on one line, with visible \n
    * string are enclosed with " by default, or with ' if string contains a "
    * if table is a class, display class name
    * tables are expanded
    ]]--
    if "string" == type( v ) then
        if keeponeline then
            v = string.gsub( v, "\n", "\\n" )
        end

        -- use clever delimiters according to content:
        -- if string contains ", enclose with '
        -- if string contains ', enclose with "
        if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
    end
    if type(v) == 'table' then
        if v.__class__ then
            return string.gsub( tostring(v), 'table', v.__class__ )
        end
        return table.tostring(v)
    end
    return tostring(v)
end

function _table_contains(t, element)
    local _, value, v

    if t then
        for _, value in pairs(t) do
            if type(value) == type(element) then
                if type(element) == 'table' then
                    if _is_table_items_equals(v, expected) then
                        return true
                    end
                else
                    if value == element then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function _is_table_items_equals(actual, expected )
    if (type(actual) == 'table') and (type(expected) == 'table') then
        local k,v
        for k,v in pairs(actual) do
            if not _table_contains(expected, v) then
                return false
            end
        end
        for k,v in pairs(expected) do
            if not _table_contains(actual, v) then
                return false
            end
        end
        return true
    elseif type(actual) ~= type(expected) then
        return false
    elseif actual == expected then
        return true
    end
    return false
end

function _is_table_equals(actual, expected)
    if (type(actual) == 'table') and (type(expected) == 'table') then
        if (#actual ~= #expected) then
            return false
        end
        local k,v
        for k,v in ipairs(actual) do
            if not _is_table_equals(v, expected[k]) then
                return false
            end
        end
        for k,v in ipairs(expected) do
            if not _is_table_equals(v, actual[k]) then
                return false
            end
        end
        for k,v in pairs(actual) do
            if not _is_table_equals(v, expected[k]) then
                return false
            end
        end
        for k,v in pairs(expected) do
            if not _is_table_equals(v, actual[k]) then
                return false
            end
        end
        return true
    elseif type(actual) ~= type(expected) then
        return false
    elseif actual == expected then
        return true
    end
    return false
end

----------------------------------------------------------------
--
--                     assertions
--
----------------------------------------------------------------

function errorMsgEquality(actual, expected)
    local errorMsg
    if not ORDER_ACTUAL_EXPECTED then
        expected, actual = actual, expected
    end
    if type(expected) == 'string' then
        errorMsg = "expected: "..prettystr(expected).."\n"..
                         "actual: "..prettystr(actual).."\n"
    else
        errorMsg = "expected: "..prettystr(expected)..", actual: "..prettystr(actual)
    end
    return errorMsg
end

function assertError(f, ...)
    -- assert that calling f with the arguments will raise an error
    -- example: assertError( f, 1, 2 ) => f(1,2) should generate an error
    local has_error, error_msg = not pcall( f, ... )
    if has_error then return end 
    error( "Expected an error but no error generated", 2 )
end

function assertTrue(value)
    if not value then
        error("expected: true, actual: " ..prettystr(value), 2)
    end
end

function assertFalse(value)
    if value then
        error("expected: false, actual: " ..prettystr(value), 2)
    end
end

function assertEquals(actual, expected)
    if type(actual) == 'table' and type(expected) == 'table' then
        if not _is_table_equals(actual, expected) then
            error( errorMsgEquality(actual, expected), 2 )
        end
    elseif type(actual) ~= type(expected) then
        error( errorMsgEquality(actual, expected), 2 )
    elseif actual ~= expected then
        error( errorMsgEquality(actual, expected), 2 )
    end
end

function assertAlmostEquals( actual, expected, margin )
    -- check that two floats are close by margin
    if type(actual) ~= 'number' or type(expected) ~= 'number' or type(margin) ~= 'number' then
        error('assertAlmostEquals: must supply only number arguments.\nArguments supplied: '..actual..', '..expected..', '..margin, 2)
    end
    if margin < 0 then
        error( 'assertAlmostEquals: margin must be positive, current value is '..margin, 2)
    end

    -- help lua in limit cases like assertAlmostEquals( 1.1, 1.0, 0.1)
    -- which by default does not work. We need to give margin a small boost
    realmargin = margin + 0.00000000001
    if math.abs(expected - actual) > realmargin then
        error( 'Values are not almost equal\nExpected: '..expected..' with margin of '..margin..', received: '..actual, 2)
    end
end

function assertNotEquals(actual, expected)
    if type(actual) ~= type(expected) then
        return
    end

    local genError = false
    if type(actual) == 'table' and type(expected) == 'table' then
        if not _is_table_equals(actual, expected) then
            return
        end
        genError = true
    elseif actual == expected then
        genError = true
    end
    if genError then
        error( 'Received the not expected value: ' .. prettystr(actual), 2 )
    end
end

function assertNotAlmostEquals( actual, expected, margin )
    -- check that two floats are not close by margin
    if type(actual) ~= 'number' or type(expected) ~= 'number' or type(margin) ~= 'number' then
        error('assertNotAlmostEquals: must supply only number arguments.\nArguments supplied: '..actual..', '..expected..', '..margin, 2)
    end
    if margin <= 0 then
        error( 'assertNotAlmostEquals: margin must be positive, current value is '..margin, 2)
    end

    -- help lua in limit cases like assertAlmostEquals( 1.1, 1.0, 0.1)
    -- which by default does not work. We need to give margin a small boost
    realmargin = margin + 0.00000000001
    if math.abs(expected - actual) <= realmargin then
        error( 'Values are almost equal\nExpected: '..expected..' with a difference above margin of '..margin..', received: '..actual, 2)
    end
end

function assertStrContains( str, sub, useRe )
    -- this relies on lua string.find function
    -- a string always contains the empty string
    noUseRe = not useRe
    if string.find(str, sub, 1, noUseRe) == nil then
        if noUseRe then
            s = 'substring'
        else
            s = 'regexp'
        end
        error( 'Error, '..s..' '..prettystr(sub)..' was not found in string '..prettystr(str), 2)
    end
end

function assertStrIContains( str, sub )
    -- this relies on lua string.find function
    -- a string always contains the empty string
    local lstr, lsub
    lstr = string.lower(str)
    lsub = string.lower(sub)
    if string.find(lstr, lsub, 1, true) == nil then
        error( 'Error, substring '..prettystr(sub)..' was not found (case insensitively) in string '..prettystr(str),2)
    end
end
    
function assertNotStrContains( str, sub, useRe )
    -- this relies on lua string.find function
    -- a string always contains the empty string
    noUseRe = not useRe
    if string.find(str, sub, 1, noUseRe) ~= nil then
        if noUseRe then
            s = 'substring'
        else
            s = 'regexp'
        end
        error( 'Error, '..s..' '..prettystr(sub)..' was found in string '..prettystr(str),2)
    end
end

function assertNotStrIContains( str, sub )
    -- this relies on lua string.find function
    -- a string always contains the empty string
    local lstr, lsub
    lstr = string.lower(str)
    lsub = string.lower(sub)
    if string.find(lstr, lsub, 1, true) ~= nil then
        error( 'Error, substring '..prettystr(sub)..' was found (case insensitively) in string '..prettystr(str),2)
    end
end

--[[
function assertStrMatches( str, regexp )
    -- Verify a full match for the string
    -- for a partial match, simply use assertStrContains with useRe set to true
end
]]

function errorMsgTypeMismatch( expectedType, actual )
    return "Expected: a "..expectedType..' value, actual: type '..type(actual)..', value '..prettystr(actual)
end

function assertIsNumber(value)
    if type(value) ~= 'number' then
        error( errorMsgTypeMismatch( 'number', value ), 2 )
    end
end

function assertIsString(value)
    if type(value) ~= "string" then
        error( errorMsgTypeMismatch( 'string', value ), 2 )
    end
end

function assertIsTable(value)
    if type(value) ~= 'table' then
        error( errorMsgTypeMismatch( 'table', value ), 2 )
    end
end

function assertIsBoolean(value)
    if type(value) ~= 'boolean' then
        error( errorMsgTypeMismatch( 'boolean', value ), 2 )
    end
end

function assertIsNil(value)
    if type(value) ~= "nil" then
        error( errorMsgTypeMismatch( 'nil', value ), 2 )
    end
end

function assertIsFunction(value)
    if type(value) ~= 'function' then
        error( errorMsgTypeMismatch( 'function', value ), 2 )
    end
end

function assertIs(actual, expected)
    if not ORDER_ACTUAL_EXPECTED then
        actual, expected = expected, actual
    end
    if actual ~= expected then
        error( 'Expected object and actual object are not the same\nExpected: '..prettystr(expected)..', actual: '..prettystr(actual), 2)
    end
end

function assertNotIs(actual, expected)
    if not ORDER_ACTUAL_EXPECTED then
        actual, expected = expected, actual
    end
    if actual == expected then
        error( 'Expected object and actual object are the same object: '..prettystr(expected), 2 )
    end
end

function assertItemsEquals(actual, expected)
    -- checks that the items of table expected
    -- are contained in table actual. Warning, this function
    -- is at least O(n^2)
    if not _is_table_items_equals(actual, expected ) then
        error( 'Contents of the tables are not identical:\nExpected: '..prettystr(expected)..'\nActual: '..prettystr(actual), 2 )
    end
end

assert_equals = assertEquals
assert_not_equals = assertNotEquals
assert_error = assertError
assert_true = assertTrue
assert_false = assertFalse
assert_is_number = assertIsNumber
assert_is_string = assertIsString
assert_is_table = assertIsTable
assert_is_boolean = assertIsBoolean
assert_is_nil = assertIsNil
assert_is_function = assertIsFunction
assert_is = assertIs
assert_not_is = assertNotIs

----------------------------------------------------------------
--
--                     Ouptutters
--
----------------------------------------------------------------

----------------------------------------------------------------
--                     class TapOutput
----------------------------------------------------------------

TapOutput = { -- class
    __class__ = 'TapOutput',
    runner = nil,
    result = nil,
}
TapOutput_MT = { __index = TapOutput }

    function TapOutput:new()
        local t = {}
        t.verbosity = VERBOSITY_LOW
        setmetatable( t, TapOutput_MT )
        return t
    end
    function TapOutput:startSuite() end
    function TapOutput:startClass(className) end
    function TapOutput:startTest(testName) end

    function TapOutput:addFailure( errorMsg, stackTrace )
       print(string.format("not ok %d\t%s", self.result.testCount, self.result.currentTestName ))
       if self.verbosity > VERBOSITY_LOW then
           print( prefixString( '    ', errorMsg ) )
        end
       if self.verbosity > VERBOSITY_DEFAULT then
           print( prefixString( '    ', stackTrace ) )
        end
    end

    function TapOutput:endTest(testHasFailure)
       if not self.result.currentTestHasFailure then
          print(string.format("ok     %d\t%s", self.result.testCount, self.result.currentTestName ))
       end
    end

    function TapOutput:endClass() end

    function TapOutput:endSuite()
       print("1.."..self.result.testCount)
       return self.result.failureCount
    end


-- class TapOutput end

----------------------------------------------------------------
--                     class JUnitOutput
----------------------------------------------------------------

JUnitOutput = { -- class
    __class__ = 'JUnitOutput',
    runner = nil,
    result = nil,
    xmlFile = nil,
}
JUnitOutput_MT = { __index = JUnitOutput }

    function JUnitOutput:new()
        local t = {}
        t.verbosity = VERBOSITY_LOW
        setmetatable( t, JUnitOutput_MT )
        return t
    end
    function JUnitOutput:startSuite() end
    function JUnitOutput:startClass(className) 
       xmlFile = io.open(string.lower(className) .. ".xml", "w")
       xmlFile:write('<testsuite name="' .. className .. '">\n')
    end
    function JUnitOutput:startTest(testName)
       if xmlFile then xmlFile:write('<testcase classname="' .. self.result.currentClassName .. '" name="'.. testName .. '">') end
    end

    function JUnitOutput:addFailure( errorMsg, stackTrace )
       if xmlFile then 
          xmlFile:write('<failure type="lua runtime error">' ..errorMsg .. '</failure>\n') 
          xmlFile:write('<system-err><![CDATA[' ..stackTrace .. ']]></system-err>\n')
       end
    end

    function JUnitOutput:endTest(testHasFailure)
       if xmlFile then xmlFile:write('</testcase>\n') end
    end

    function JUnitOutput:endClass() end

    function JUnitOutput:endSuite()
       if xmlFile then xmlFile:write('</testsuite>\n') end
       if xmlFile then xmlFile:close() end
       return self.result.failureCount
    end


-- class TapOutput end

----------------------------------------------------------------
--                     class TextOutput
----------------------------------------------------------------

TextOutput = { __class__ = 'TextOutput' }
TextOutput_MT = { -- class
    __index = TextOutput
}

    function TextOutput:new()
        local t = {}
        t.runner = nil
        t.result = nil
        t.errorList ={}
        t.verbosity = VERBOSITY_DEFAULT
        setmetatable( t, TextOutput_MT )
        return t
    end

    function TextOutput:startSuite()
    end

    function TextOutput:startClass(className)
        if self.verbosity > VERBOSITY_DEFAULT then
            print( '>>>>>>>>> '.. self.result.currentClassName )
        end
    end

    function TextOutput:startTest(testName)
        if self.verbosity > VERBOSITY_LOW then 
            print( ">>> ".. self.result.currentTestName ) 
        end 
    end 

    function TextOutput:addFailure( errorMsg, stackTrace ) 
        table.insert( self.errorList, { self.result.currentTestName, errorMsg, stackTrace } ) 
        if self.verbosity == 0 then
            io.stdout:write("F") 
        end
        if self.verbosity > VERBOSITY_LOW then
            print( errorMsg )
            print( 'Failed' )
        end
    end

    function TextOutput:endTest(testHasFailure)
        if not testHasFailure then
            if self.verbosity > VERBOSITY_LOW then
                --print ("Ok" )
            else 
                io.stdout:write(".")
            end
        end
    end

    function TextOutput:endClass()
        if self.verbosity > VERBOSITY_LOW then
           print()
        end
    end

    function TextOutput:displayOneFailedTest( failure )
        testName, errorMsg, stackTrace = unpack( failure )
        print(">>> "..testName.." failed")
        print( errorMsg )
        if self.verbosity > VERBOSITY_DEFAULT then
            print( stackTrace )
        end
    end

    function TextOutput:displayFailedTests()
        if #self.errorList == 0 then return end
        print("Failed tests:")
        print("-------------")
        for i,v in ipairs(self.errorList) do
            self:displayOneFailedTest( v )
        end
        print()
    end

    function TextOutput:endSuite()
        if self.verbosity == VERBOSITY_LOW then
            print()
        else
            print("=========================================================")
        end
        self:displayFailedTests()
        local successPercent, successCount
        successCount = self.result.testCount - self.result.failureCount
        if self.result.testCount == 0 then
            successPercent = 100
        else
            successPercent = math.ceil( 100 * successCount / self.result.testCount )
        end
        print( string.format("Suite run in: %f seconds.", self.result.duration))
        print( string.format("Success: %d%% - %d / %d",
            successPercent, successCount, self.result.testCount) )
    end


-- class TextOutput end


----------------------------------------------------------------
--                     class NilOutput
----------------------------------------------------------------

function nopCallable() 
    --print(42) 
    return nopCallable
end

NilOutput = {
    __class__ = 'NilOuptut',    
}
NilOutput_MT = {
    __index = nopCallable,
}
function NilOutput:new()
    local t = {}
    t.__class__ = 'NilOutput'
    setmetatable( t, NilOutput_MT )
    return t 
end

----------------------------------------------------------------
--
--                     class LuaUnit
--
----------------------------------------------------------------

LuaUnit = {
    outputType = TextOutput,
    verbosity = VERBOSITY_DEFAULT,
    __class__ = 'LuaUnit'
}
LuaUnit_MT = { __index = LuaUnit }

    function LuaUnit:new()
        local t = {}
        setmetatable( t, LuaUnit_MT )
        return t
    end

    -----------------[[ Utility methods ]]---------------------

    function LuaUnit.isFunction(aObject) 
        -- return true if aObject is a function
        return 'function' == type(aObject)
    end

    function LuaUnit.isClassMethod(aName)
        -- return true if aName contains a class + a method name in the form class:method
        return not not string.find(aName, ':' )
    end

    function LuaUnit.splitClassMethod(someName)
        -- return a pair className, methodName for a name in the form class:method
        -- return nil if not a class + method name
        -- name is class + method
        local hasMethod
        hasMethod = string.find(someName, ':' )
        if not hasMethod then return nil end
        methodName = string.sub(someName, hasMethod+1)
        className = string.sub(someName,1,hasMethod-1)
        return className, methodName
    end

    function LuaUnit.isMethodTestName( s )
        -- return true is the name matches the name of a test method
        -- default rule is that is starts with 'Test' or with 'test'
        if string.sub(s,1,4):lower() == 'test' then 
            return true
        end
        return false
    end

    function LuaUnit.isTestName( s )
        -- return true is the name matches the name of a test
        -- default rule is that is starts with 'Test' or with 'test'
        if string.sub(s,1,4):lower() == 'test' then 
            return true
        end
        return false
    end

    function LuaUnit.collectTests()
        -- return a list of all test names in the global namespace
        -- that match LuaUnit.isTestName

        testNames = {}
        for key, val in pairs(_G) do 
            if LuaUnit.isTestName( key ) then
                table.insert( testNames , key )
            end
        end
        table.sort( testNames )
        return testNames 
    end

    function LuaUnit.parseCmdLine( cmdLine )
        -- parse the command line 
        -- Supported command line parameters:
        -- --verbose, -v: increase verbosity
        -- --quiet, -q: silence output
        -- --output, -o, + name: select output type
        -- --pattern, -p, + pattern: run test matching pattern, may be repeated
        -- [testnames, ...]: run selected test names
        --
        -- Returnsa table with the following fields:
        -- verbosity: nil, VERBOSITY_DEFAULT, VERBOSITY_QUIET, VERBOSITY_VERBOSE
        -- output: nil, 'tap', 'junit', 'text', 'nil'
        -- testNames: nil or a list of test names to run
        -- pattern: nil or a list of patterns

        local result = {}
        local state = nil
        local SET_OUTPUT = 1
        local SET_PATTERN = 2

        if cmdLine == nil then
            return result
        end

        local function parseOption( arg )
            if arg == '--verbose' or arg == '-v' then
                result['verbosity'] = VERBOSITY_VERBOSE
                return
            end
            if arg == '--quiet' or arg == '-q' then
                result['verbosity'] = VERBOSITY_QUIET
                return
            end
            if arg == '--output' or arg == '-o' then
                state = SET_OUTPUT
                return state
            end
            if arg == '--pattern' or arg == '-p' then
                state = SET_PATTERN
                return state
            end
            error('Unknown option: '..arg)
        end

        local function setArg( arg, state )
            if state == SET_OUTPUT then
                result['output'] = arg
                return
            end
            if state == SET_PATTERN then
                if result['pattern'] then
                    table.insert( result['pattern'], arg )
                else
                    result['pattern'] = { arg }
                end
                return
            end
            error('Unknown parse state: '.. state)
        end


        for i, arg in ipairs(cmdLine) do
            if state ~= nil then
                setArg( arg, state, result )
                state = nil
            else 
                if arg:sub(1,1) == '-' then
                    state = parseOption( arg )
                else 
                    if result['testNames'] then
                        table.insert( result['testNames'], arg )
                    else
                        result['testNames'] = { arg }
                    end
                end
            end
        end

        if state ~= nil then
            error('Missing argument after '..cmdLine[ #cmdLine ] )
        end

        return result
    end

    --------------[[ Output methods ]]-------------------------

    function LuaUnit:ensureSuiteStarted( )
        if self.result and self.result.suiteStarted then
            return
        end
        self:startSuite()
    end

    function LuaUnit:startSuite()
        self.result = {}
        self.result.failureCount = 0
        self.result.testCount = 0
        self.result.currentTestName = ""
        self.result.currentClassName = ""
        self.result.currentTestHasFailure = false
        self.result.suiteStarted = true
        self.result.startTime = os.clock()
        self.outputType = self.outputType or TextOutput
        self.output = self.outputType:new()
        self.output.runner = self
        self.output.result = self.result
        self.output.verbosity = self.verbosity
        self.output:startSuite()
    end

    function LuaUnit:startClass( className )
        self.result.currentClassName = className
        self.output:startClass( className )
    end

    function LuaUnit:startTest( testName  )
        self.result.currentTestName = testName
        self.result.testCount = self.result.testCount + 1
        self.result.currentTestHasFailure = false
        self.output:startTest( testName )
    end

    function LuaUnit:addFailure( errorMsg, stackTrace )
        if not self.result.currentTestHasFailure then
            self.result.failureCount = self.result.failureCount + 1
            self.result.currentTestHasFailure = true
        end
        self.output:addFailure( errorMsg, stackTrace )
    end

    function LuaUnit:endTest()
        self.output:endTest( self.result.currentTestHasFailure )
        self.result.currentTestName = ""
        self.result.currentTestHasFailure = false
    end

    function LuaUnit:endClass()
        self.output:endClass()
    end

    function LuaUnit:endSuite()
        if self.result.suiteStarted == false then
            error('LuaUnit:endSuite() -- suite was already ended' )
        end
        self.result.duration = os.clock()-self.result.startTime
        self.result.suiteStarted = false
        self.output:endSuite()
    end

    function LuaUnit:setOutputType(outputType)
        -- default to text
        -- tap produces results according to TAP format
        if outputType:upper() == "NIL" then
            self.outputType = NilOutput
            return
        end
        if outputType:upper() == "TAP" then
            self.outputType = TapOutput
            return
        end 
        if outputType:upper() == "JUNIT" then
            self.outputType = JUnitOutput
            return
        end 
        if outputType:upper() == "TEXT" then
            self.outputType = TextOutput
            return
        end
        error( 'No such format: '..outputType)
    end

    function LuaUnit:setVerbosity( verbosity )
        self.verbosity = verbosity
    end

    --------------[[ Runner ]]-----------------

    SPLITTER = '\n>----------<\n'

    function LuaUnit:protectedCall( classInstance , methodInstance)
        -- if classInstance is nil, this is just a function run
        local function err_handler(e)
            return debug.traceback(e..SPLITTER, 4)
        end

        local ok=true, errorMsg, stackTrace
        if classInstance then
            -- stupid Lua < 5.2 does not allow xpcall with arguments so let's live with that
            ok, errorMsg = xpcall( function () methodInstance(classInstance) end, err_handler )
        else
            ok, errorMsg = xpcall( function () methodInstance() end, err_handler )
        end
        if not ok then
            t = strsplit( SPLITTER, errorMsg )
            stackTrace = string.sub(t[2],2)
            self:addFailure( t[1], stackTrace )
        end

        return ok
    end


    function LuaUnit:execOneFunction(className, methodName, classInstance, methodInstance)
        -- When executing a test function, className and classInstance must be nil
        -- When executing a class method, all parameters must be set

        if type(methodInstance) ~= 'function' then
            error( tostring(methodName)..'must be a function, not '..type(methodInstance))
        end

        if className == nil then
            className = '<TestFunction>'
        end

        if self.lastClassName ~= className then
            if self.lastClassName ~= nil then
                self:endClass()
            end
            self:startClass( className )
            self.lastClassName = className
        end

        self:startTest(className..':'..methodName)

        -- run setUp first(if any)
        if classInstance and self.isFunction( classInstance.setUp ) then
            self:protectedCall( classInstance, classInstance.setUp)
        end

        -- run testMethod()
        if not self.result.currentTestHasFailure then
            self:protectedCall( classInstance, methodInstance)
        end

        -- lastly, run tearDown(if any)
        if classInstance and self.isFunction(classInstance.tearDown) then
            self:protectedCall( classInstance, classInstance.tearDown)
        end

        self:endTest()
    end

    function LuaUnit:execOneClass( className, classInstance )
        -- execute all test methods of class classInstance whose name is className
        -- both arguments are mandatory
        self:ensureSuiteStarted()

        for methodName, methodInstance in sortedPairs(classInstance) do
            if LuaUnit.isFunction(methodInstance) and LuaUnit.isMethodTestName( methodName ) then
                self:execOneFunction( className, methodName, classInstance, methodInstance )
            end
        end
    end

    function LuaUnit:runSuiteByInstances( listOfNameAndInst )
        -- Run an explicit list of tests. All test instances and names must be supplied.
        -- each test must be one of:
        --   * { function name, function instance }
        --   * { class name, class instance }
        --   * { class:method name, class instance }
        self:ensureSuiteStarted()

        for i,v in ipairs( listOfNameAndInst ) do
            name, instance = v[1], v[2]
            if LuaUnit.isFunction(instance) then
                self:execOneFunction( nil, name, nil, instance )
                return
            else 
                if type(instance) ~= 'table' then
                    error( 'Instance must be a table or a function, not a '..type(instance)..', value '..prettystr(instance))
                else

                    if LuaUnit.isClassMethod( name ) then
                        className, instanceName = LuaUnit.splitClassMethod( name )
                        methodInstance = instance[methodName]
                        if methodInstance == nil then
                            error( "Could not find method in class "..tostring(className).." for method "..tostring(methodName) )
                        end
                        self:execOneFunction( className, methodName, instance, methodInstance )
                    else
                        self:execOneClass( name, instance )
                    end
                end
            end
        end
    end

    function LuaUnit:runSuiteByNames( listOfName )
        -- Run an explicit list of test names

        self:ensureSuiteStarted()

        listOfNameAndInst = {}

        for i,name in ipairs( listOfName ) do
            if LuaUnit.isClassMethod( name ) then
                className, methodName = LuaUnit.splitClassMethod( name )
                instanceName = className
                instance = _G[instanceName]

                if instance == nil then
                    error( "No such name in global space: "..instanceName )
                end

                if type(instance) ~= 'table' then
                    error( 'Instance of '..instanceName..' must be a table, not '..type(instance))
                end

                methodInstance = instance[methodName]
                if methodInstance == nil then
                    error( "Could not find method in class "..tostring(className).." for method "..tostring(methodName) )
                end

            else
                -- for functions and classes
                instanceName = name
                instance = _G[instanceName]
            end

            if instance == nil then
                error( "No such name in global space: "..instanceName )
            end

            if (type(instance) ~= 'table' and type(instance) ~= 'function') then
                error( 'Name must match a function or a table: '..instanceName )
            end

            table.insert( listOfNameAndInst, { name, instance } )
        end

        self:runSuiteByInstances( listOfNameAndInst )
    end

    function LuaUnit:run(...)
        -- Run some specific test classes.
        -- If no arguments are passed, run the class names specified on the
        -- command line. If no class name is specified on the command line
        -- run all classes whose name starts with 'Test'
        --
        -- If arguments are passed, they must be strings of the class names 
        -- that you want to run
        local runner = self:new()
        local outputType = os.getenv("outputType")
        if outputType then LuaUnit:setOutputType(outputType) end
        return runner:runSuite(...)
    end

    function LuaUnit:runSuite( ... )

        local args={...};
        if #args == 0 then
            args = argv
        end

        options = LuaUnit.parseCmdLine( args )

        if options.verbosity then
            self.verbosity = options.verbosity
        end

        if options.output then
            self:setOutputType(options.output)
        end

        -- do something with patterns

        testNames = options['testNames']

        if testNames == nil then
            -- create the list of classes to run now ! If not, you can
            -- not iterate over _G while modifying it.
            testNames = LuaUnit.collectTests()
        end

        self:runSuiteByNames( testNames )

        if self.lastClassName ~= nil then
            self:endClass()
        end
        self:endSuite()
        return self.result.failureCount
    end
-- class LuaUnit
