--[[ 
        luaunit.lua

Description: A unit testing framework
Homepage: https://github.com/bluebird75/luaunit
Development by Philippe Fremy <phil@freehackers.org>
Based on initial work of Ryu, Gwang (http://www.gpgstudy.com/gpgiki/LuaUnit)
License: BSD License, see LICENSE.txt
Version: 3.0
]]--

VERSION='3.0'

--[[ Some people like assertEquals( actual, expected ) and some people prefer 
assertEquals( expected, actual ).
]]--
ORDER_ACTUAL_EXPECTED = true
PRINT_TABLE_REF_IN_ERROR_MSG = false
LINE_LENGTH=80

VERBOSITY_DEFAULT = 10
VERBOSITY_LOW     = 1
VERBOSITY_QUIET   = 0
VERBOSITY_VERBOSE = 20 

-- we need to keep a copy of the script args before it is overriden
cmdline_argv = arg

USAGE=[[Usage: lua <your_test_suite.lua> [options] [testname1 [testname2] ... ]
Options:
  -h, --help:             Print this help
  --version:              Print version information
  -v, --verbose:          Increase verbosity
  -q, --quiet:            Set verbosity to minimum
  -o, --output OUTPUT:    Set output type to OUTPUT
                          Possible values: text, tap, junit, nil
  -n, --name NAME:        For junit only, mandatory name of xml file 
  -p, --pattern PATTERN:  Execute all test names matching the lua PATTERN
                          May be repeated to include severals patterns
                          Make sure you esape magic chars like +? with %
  testname1, testname2, ... : tests to run in the form of testFunction, 
                              TestClass or TestClass.testMethod
]]

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

-- Contains the keys of the table being iterated, already sorted
-- and the last index that has been iterated
-- Example: 
--    t a table on which we iterate
--    sortedNextCache[ t ].idx is the sorted index of the table
--    sortedNextCache[ t ].lastIdx is the last index used in the sorted index
sortedNextCache = {}

function sortedNext(t, state)
    -- Equivalent of the next() function of table iteration, but returns the
    -- keys in the alphabetic order. We use a temporary sorted key table that
    -- is stored in a global variable. We also store the last index
    -- used in the iteration to find the next one quickly

    --print("sortedNext: state = "..tostring(state) )
    local key
    if state == nil then
        -- the first time, generate the index
        -- cleanup the previous index, just in case...
        sortedNextCache[ t ] = nil
        sortedNextCache[ t ] = { idx=__genSortedIndex( t ), lastIdx=1 }
        key = sortedNextCache[t].idx[1]
        return key, t[key]
    end

    -- normally, the previous index in the orderedTable is there:
    lastIndex = sortedNextCache[ t ].lastIdx
    if sortedNextCache[t].idx[lastIndex] == state then
        key = sortedNextCache[t].idx[lastIndex+1]
        sortedNextCache[ t ].lastIdx = lastIndex+1
    else
        -- strange, we have to find the next value by ourselves
        key = nil
        for i = 1,#sortedNextCache[t] do
            if sortedNextCache[t].idx[i] == state then
                key = sortedNextCache[t].idx[i+1]
                sortedNextCache[ t ].lastIdx = i+1
                -- break
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    sortedNextCache[t] = nil
    return
end

function sortedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in sorted order. This works only if the key types are all the same
    -- and support comparison
    return sortedNext, t, nil
end

function strsplit(delimiter, text)
-- Split text into a list consisting of the strings in text,
-- separated by strings matching delimiter (which may be a pattern). 
-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
    local list = {}
    local pos = 1
    if string.find("", delimiter, 1, true) then -- this would result in endless loops
        error("delimiter matches empty string!")
    end
    while 1 do
        local first, last = string.find(text, delimiter, pos, true)
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

function hasNewLine( s )
    -- return true if s has a newline
    return (string.find(s, '\n', 1, true) ~= nil)
end

function prefixString( prefix, s )
    -- Prefix all the lines of s with prefix
    local t, s2
    t = strsplit('\n', s)
    s2 = prefix..table.concat(t, '\n'..prefix)
    return s2
end

function strMatch(s, pattern, start, final )
    -- return true if s matches completely the pattern from index start to index end
    -- return false in every other cases
    -- if start is nil, matches from the beginning of the string
    -- if end is nil, matches to the end of the string
    if start == nil then
        start = 1
    end

    if final == nil then
        final = string.len(s)
    end

    foundStart, foundEnd = string.find(s, pattern, start, false)
    if not foundStart then
        -- no match
        return false
    end
    
    if foundStart == start and foundEnd == final then
        return true
    end

    return false
end

function xmlEscape( s )
    -- Return s escaped for XML attributes
    -- escapes table:
    -- "   &quot;
    -- '   &apos;
    -- <   &lt;
    -- >   &gt;
    -- &   &amp;
    local substTable = {
        { '&',   "&amp;" },
        { '"',   "&quot;" },
        { "'",   "&apos;" },
        { '<',   "&lt;" },
        { '>',   "&gt;" },
    }

    for k, v in ipairs( substTable ) do
        s = string.gsub( s, v[1], v[2] )
    end

    return s
end

function xmlCDataEscape( s )
    -- Return s escaped for CData section
    -- escapes: "]]>" 
    s = string.gsub( s, ']]>', ']]&gt;' )
    return s
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

function table.tostring( tbl, indentLevel, printTableRefs, recursionTable )
    printTableRefs = printTableRefs or PRINT_TABLE_REF_IN_ERROR_MSG
    recursionTable = recursionTable or {}
    recursionTable[tbl] = true

    local result, done = {}, {}
    local dispOnMultLines = false

    for k, v in ipairs( tbl ) do
        if recursionTable[v] then
            -- recursion detected!
            recursionTable['recursionDetected'] = true
            table.insert( result, "<"..tostring(v)..">" )
        else
            table.insert( result, prettystr_sub( v, indentLevel+1, false, printTableRefs, recursionTable ) )
        end

        done[ k ] = true
    end

    for k, v in sortedPairs( tbl ) do
        if not done[ k ] then
            if recursionTable[v] then
                -- recursion detected!
                recursionTable['recursionDetected'] = true
                table.insert( result, table.keytostring( k ) .. "=" .. "<"..tostring(v)..">" )
            else
                table.insert( result,
                    table.keytostring( k ) .. "=" .. prettystr_sub( v, indentLevel+1, true, printTableRefs, recursionTable ) )
            end
        end
    end
    if printTableRefs then
        table_ref = "<"..tostring(tbl).."> "
    else
        table_ref = ''
    end

    local SEP_LENGTH=2     -- ", "
    local totalLength = 0
    for k, v in ipairs( result ) do
        l = string.len( v )
        totalLength = totalLength + l
        if l > LINE_LENGTH-1 then
            dispOnMultLines = true
        end
    end
    -- adjust with length of separator
    totalLength = totalLength + SEP_LENGTH * math.max( 0, #result-1) + 2 -- two items need 1 sep, thee items two seps + len of '{}'
    if totalLength > LINE_LENGTH-1 then
        dispOnMultLines = true
    end

    if dispOnMultLines then
        indentString = string.rep("    ", indentLevel)
        closingIndentString = string.rep("    ", math.max(0, indentLevel-1) )
        result_str = table_ref.."{\n"..indentString .. table.concat( result, ",\n"..indentString  ) .. "\n"..closingIndentString.."}"
    else
        result_str = table_ref.."{".. table.concat( result, ", " ) .. "}"
    end
    return result_str
end

function prettystr( v, keeponeline )
    --[[ Better string conversion, to display nice variable content:
    For strings, if keeponeline is set to true, string is displayed on one line, with visible \n
    * string are enclosed with " by default, or with ' if string contains a "
    * if table is a class, display class name
    * tables are expanded
    ]]--
    recursionTable = {}
    s = prettystr_sub(v, 1, keeponeline, PRINT_TABLE_REF_IN_ERROR_MSG, recursionTable)
    if recursionTable['recursionDetected'] == true and PRINT_TABLE_REF_IN_ERROR_MSG == false then
        -- some table contain recursive references, 
        -- so we must recompute the value by including all table references
        -- else the result looks like crap
        recursionTable = {}
        s = prettystr_sub(v, 1, keeponeline, true, recursionTable)
    end
    return s
end

function prettystr_sub(v, indentLevel, keeponeline, printTableRefs, recursionTable )
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
        --if v.__class__ then
        --    return string.gsub( tostring(v), 'table', v.__class__ )
        --end
        return table.tostring(v, indentLevel, printTableRefs, recursionTable)
    end
    return tostring(v)
end

function _table_contains(t, element)
    local _, value, v

    if t then
        for _, value in pairs(t) do
            if type(value) == type(element) then
                if type(element) == 'table' then
                    -- if we wanted recursive items content comparison, we could use
                    -- _is_table_items_equals(v, expected) but one level of just comparing
                    -- items is sufficient
                    if _is_table_equals( value, element ) then
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
    expectedStr = prettystr(expected)
    actualStr = prettystr(actual)
    if type(expected) == 'string' or type(expected) == 'table' then
        if hasNewLine( expectedStr..actualStr ) then
            expectedStr = '\n'..expectedStr
            actualStr = '\n'..actualStr
        end
        errorMsg = "expected: "..expectedStr.."\n"..
                         "actual: "..actualStr
    else
        errorMsg = "expected: "..expectedStr..", actual: "..actualStr
    end
    return errorMsg
end

function assertError(f, ...)
    -- assert that calling f with the arguments will raise an error
    -- example: assertError( f, 1, 2 ) => f(1,2) should generate an error
    local no_error, error_msg = pcall( f, ... )
    if not no_error then return end 
    error( "Expected an error when calling function but no error generated", 2 )
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

function assertNil(value)
    if value ~= nil then
        error("expected: nil, actual: " ..prettystr(value), 2)
    end
end

function assertNotNil(value)
    if value == nil then
        error("expected non nil value, received nil", 2)
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

    if not ORDER_ACTUAL_EXPECTED then
        expected, actual = actual, expected
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

    if not ORDER_ACTUAL_EXPECTED then
        expected, actual = actual, expected
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
            subType = 'substring'
        else
            subType = 'regexp'
        end
        local subPretty = prettystr(sub)
        local strPretty = prettystr(str)
        if hasNewLine( subPretty..strPretty ) then
            subPretty = '\n'..subPretty..'\n'
            strPretty = '\n'..strPretty
        end
        error( 'Error, '..subType..' '..subPretty..' was not found in string '..strPretty, 2)
    end
end

function assertStrIContains( str, sub )
    -- this relies on lua string.find function
    -- a string always contains the empty string
    local lstr, lsub, subPretty, strPretty
    lstr = string.lower(str)
    lsub = string.lower(sub)
    if string.find(lstr, lsub, 1, true) == nil then
        subPretty = prettystr(sub)
        strPretty = prettystr(str)
        if hasNewLine( subPretty..strPretty ) then
            subPretty = '\n'..subPretty..'\n'
            strPretty = '\n'..strPretty
        end
        error( 'Error, substring '..subPretty..' was not found (case insensitively) in string '..strPretty,2)
    end
end
    
function assertNotStrContains( str, sub, useRe )
    -- this relies on lua string.find function
    -- a string always contains the empty string
    noUseRe = not useRe
    if string.find(str, sub, 1, noUseRe) ~= nil then
        local substrType
        if noUseRe then
            substrType = 'substring'
        else
            substrType = 'regexp'
        end
        local subPretty = prettystr(sub)
        local strPretty = prettystr(str)
        if hasNewLine( subPretty..strPretty ) then
            subPretty = '\n'..subPretty..'\n'
            strPretty = '\n'..strPretty
        end
        error( 'Error, '..substrType..' '..subPretty..' was found in string '..strPretty,2)
    end
end

function assertNotStrIContains( str, sub )
    -- this relies on lua string.find function
    -- a string always contains the empty string
    local lstr, lsub
    lstr = string.lower(str)
    lsub = string.lower(sub)
    if string.find(lstr, lsub, 1, true) ~= nil then
        local subPretty = prettystr(sub)
        local strPretty = prettystr(str)
        if hasNewLine( subPretty..strPretty) then
            subPretty = '\n'..subPretty..'\n'
            strPretty = '\n'..strPretty
        end
        error( 'Error, substring '..subPretty..' was found (case insensitively) in string '..strPretty,2)
    end
end

function assertStrMatches( str, pattern, start, final )
    -- Verify a full match for the string
    -- for a partial match, simply use assertStrContains with useRe set to true
    if not strMatch( str, pattern, start, final ) then
        local patternPretty = prettystr(pattern)
        local strPretty = prettystr(str)
        if hasNewLine( patternPretty..strPretty) then
            patternPretty = '\n'..patternPretty..'\n'
            strPretty = '\n'..strPretty
        end
        error( 'Error, pattern '..patternPretty..' was not matched by string '..strPretty,2)
    end
end

function assertErrorMsgEquals( expectedMsg, func, ... )
    -- assert that calling f with the arguments will raise an error
    -- example: assertError( f, 1, 2 ) => f(1,2) should generate an error
    local no_error, error_msg = pcall( func, ... )
    if no_error then
        error( 'No error generated when calling function but expected error: "'..expectedMsg..'"', 2 )
    end
    if not (error_msg == expectedMsg) then
        if hasNewLine( error_msg..expectedMsg ) then
            expectedMsg = '\n'..expectedMsg
            error_msg = '\n'..error_msg
        end
        error( 'Exact error message expected: "'..expectedMsg..'"\nError message received: "'..error_msg..'"\n',2)
    end
end

function assertErrorMsgContains( partialMsg, func, ... )
    -- assert that calling f with the arguments will raise an error
    -- example: assertError( f, 1, 2 ) => f(1,2) should generate an error
    local no_error, error_msg = pcall( func, ... )
    if no_error then
        error( 'No error generated when calling function but expected error containing: '..prettystr(partialMsg), 2 )
    end
    if not string.find( error_msg, partialMsg, nil, true ) then
        local partialMsgStr = prettystr(partialMsg)
        local errorMsgStr = prettystr(error_msg)
        if hasNewLine(error_msg..partialMsg) then
            partialMsgStr = '\n'..partialMsgStr
            errorMsgStr = '\n'..errorMsgStr
        end
        error( 'Error message does not contain: '..partialMsgStr..'\nError message received: '..errorMsgStr..'\n',2)
    end
end

function assertErrorMsgMatches( expectedMsg, func, ... )
    -- assert that calling f with the arguments will raise an error
    -- example: assertError( f, 1, 2 ) => f(1,2) should generate an error
    local no_error, error_msg = pcall( func, ... )
    if no_error then
        error( 'No error generated when calling function but expected error matching: "'..expectedMsg..'"', 2 )
    end
    if not strMatch( error_msg, expectedMsg ) then
        if hasNewLine(error_msg..expectedMsg) then
            expectedMsg = '\n'..expectedMsg
            error_msg = '\n'..error_msg
        end
        error( 'Error message does not match: "'..expectedMsg..'"\nError message received: "'..error_msg..'"\n',2)
    end
end

function errorMsgTypeMismatch( expectedType, actual )
    local actualStr = prettystr(actual)
    if hasNewLine(actualStr) then
        actualStr =  '\n'..actualStr
    end
    return "Expected: a "..expectedType..' value, actual: type '..type(actual)..', value '..actualStr
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

function assertIsUserdata(value)
    if type(value) ~= 'userdata' then
        error( errorMsgTypeMismatch( 'userdata', value ), 2 )
    end
end

function assertIsCoroutine(value)
    if type(value) ~= 'thread' then
        error( errorMsgTypeMismatch( 'thread', value ), 2 )
    end
end

assertIsThread = assertIsCoroutine

function assertIs(actual, expected)
    if not ORDER_ACTUAL_EXPECTED then
        actual, expected = expected, actual
    end
    if actual ~= expected then
        local expectedStr = prettystr(expected)
        local actualStr = prettystr(actual)
        if hasNewLine(expectedStr..actualStr) then
            expectedStr = '\n'..expectedStr..'\n'
            actualStr =  '\n'..actualStr
        else
            expectedStr = expectedStr..', '
        end
        error( 'Expected object and actual object are not the same\nExpected: '..expectedStr..'actual: '..actualStr, 2)
    end
end

function assertNotIs(actual, expected)
    if not ORDER_ACTUAL_EXPECTED then
        actual, expected = expected, actual
    end
    if actual == expected then
        local expectedStr = prettystr(expected)
        if hasNewLine(expectedStr) then
            expectedStr = '\n'..expectedStr
        end
        error( 'Expected object and actual object are the same object: '..expectedStr, 2 )
    end
end

function assertItemsEquals(actual, expected)
    -- checks that the items of table expected
    -- are contained in table actual. Warning, this function
    -- is at least O(n^2)
    if not _is_table_items_equals(actual, expected ) then
        local expectedStr = prettystr(expected)
        local actualStr = prettystr(actual)
        if hasNewLine(expectedStr..actualStr) then
            expectedStr = '\n'..expectedStr
            actualStr =  '\n'..actualStr
        end
        error( 'Contents of the tables are not identical:\nExpected: '..expectedStr..'\nActual: '..actualStr, 2 )
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

    -- For a good reference for TAP format, check: http://testanything.org/tap-specification.html

    function TapOutput:new()
        local t = {}
        t.verbosity = VERBOSITY_LOW
        setmetatable( t, TapOutput_MT )
        return t
    end
    function TapOutput:startSuite() 
        print("1.."..self.result.testCount)
        print('# Started on '..self.result.startDate)
    end
    function TapOutput:startClass(className) 
        if className ~= '[TestFunctions]' then
            print('# Starting class: '..className)
        end
    end
    function TapOutput:startTest(testName) end

    function TapOutput:addFailure( errorMsg, stackTrace )
        print(string.format("not ok %d\t%s", self.result.currentTestNumber, self.result.currentNode.testName ))
        if self.verbosity > VERBOSITY_LOW then
           print( prefixString( '    ', errorMsg ) )
        end
        if self.verbosity > VERBOSITY_DEFAULT then
           print( prefixString( '    ', stackTrace ) )
        end
    end

    function TapOutput:endTest(testHasFailure)
        if not self.result.currentNode:hasFailure() then
            print(string.format("ok     %d\t%s", self.result.currentTestNumber, self.result.currentNode.testName ))
        end
    end

    function TapOutput:endClass() end

    function TapOutput:endSuite()
        t = {}
        table.insert(t, string.format('# Ran %d tests in %0.3f seconds, %d successes, %d failures',
            self.result.testCount, self.result.duration, self.result.testCount-self.result.failureCount, self.result.failureCount ) )
        if self.result.nonSelectedCount > 0 then
            table.insert(t, string.format(", %d non selected tests", self.result.nonSelectedCount ) )
        end
        print( table.concat(t) )
        return self.result.failureCount
    end


-- class TapOutput end

----------------------------------------------------------------
--                     class JUnitOutput
----------------------------------------------------------------

-- For more junit format information, check: 
-- https://svn.jenkins-ci.org/trunk/hudson/dtkit/dtkit-format/dtkit-junit-model/src/main/resources/com/thalesgroup/dtkit/junit/model/xsd/junit-4.xsd
JUnitOutput = { -- class
    __class__ = 'JUnitOutput',
    runner = nil,
    result = nil,
}
JUnitOutput_MT = { __index = JUnitOutput }

    function JUnitOutput:new()
        local t = {}
        t.testList = {}
        t.verbosity = VERBOSITY_LOW
        t.fd = nil
        t.fname = nil
        setmetatable( t, JUnitOutput_MT )
        return t
    end
    function JUnitOutput:startSuite()
        if self.fname == nil then
            error('With Junit, an output filename must be supplied with --name!')
        end
        if string.sub(self.fname,-4) ~= '.xml' then
            self.fname = self.fname..'.xml'
        end
        self.fd = io.open(self.fname, "w")
        if self.fd == nil then
            error("Could not open file for writing: "..self.fname)
        end
        print('# XML output to '..self.fname)
        print('# Started on '..self.result.startDate)
        self.fd:write('<testsuites>\n')
    end
    function JUnitOutput:startClass(className) 
        if className ~= '[TestFunctions]' then
            print('# Starting class: '..className)
        end
        self.fd:write('    <testsuite name="' .. className .. '">\n')
    end
    function JUnitOutput:startTest(testName)
        print('# Starting test: '..testName)
        self.fd:write('        <testcase classname="' .. self.result.currentNode.className .. '"\n            name="'.. testName .. '">\n')
    end

    function JUnitOutput:addFailure( errorMsg, stackTrace )
        print('# Failure: '..errorMsg)
        print('# '..stackTrace)
        self.fd:write('            <failure type="' ..xmlEscape(errorMsg) .. '">\n')  
        self.fd:write('                <![CDATA[' ..xmlCDataEscape(stackTrace) .. ']]></failure>\n')
    end

    function JUnitOutput:endTest(testHasFailure)
        self.fd:write('        </testcase>\n')
    end

    function JUnitOutput:endClass()
        self.fd:write('    </testsuite>\n')
    end

    function JUnitOutput:endSuite()
        t = {}
        table.insert(t, string.format('# Ran %d tests in %0.3f seconds, %d successes, %d failures',
            self.result.testCount, self.result.duration, self.result.testCount-self.result.failureCount, self.result.failureCount ) )
        if self.result.nonSelectedCount > 0 then
            table.insert(t, string.format(", %d non selected tests", self.result.nonSelectedCount ) )
        end
        print( table.concat(t) )
        self.fd:write('</testsuites>\n') 
        self.fd:close()
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
        if self.verbosity > VERBOSITY_QUIET then
            print( 'Started on '.. self.result.startDate )
        end
    end

    function TextOutput:startClass(className)
        if self.verbosity > VERBOSITY_LOW then
            print( '>>>>>>>>> '.. self.result.currentClassName )
        end
    end

    function TextOutput:startTest(testName)
        if self.verbosity > VERBOSITY_LOW then 
            print( ">>> ".. self.result.currentNode.testName ) 
        end 
    end 

    function TextOutput:addFailure( errorMsg, stackTrace ) 
        table.insert( self.errorList, { self.result.currentNode.testName, errorMsg, stackTrace } ) 
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
        if self.verbosity > VERBOSITY_LOW then
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
        if self.verbosity <= VERBOSITY_LOW then
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
        print( string.format("Success: %d%% - %d / %d, executed in %0.3f seconds",
            successPercent, successCount, self.result.testCount, self.result.duration) )
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
        return not not string.find(aName, '.', nil, true )
    end

    function LuaUnit.splitClassMethod(someName)
        -- return a pair className, methodName for a name in the form class:method
        -- return nil if not a class + method name
        -- name is class + method
        local hasMethod
        hasMethod = string.find(someName, '.', nil, true )
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
        -- --name, -n, + fname: name of output file for junit, default to stdout
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
        local SET_FNAME = 3

        if cmdLine == nil then
            return result
        end

        local function parseOption( option )
            if option == '--help' or option == '-h' then
                result['help'] = true
                return
            end
            if option == '--version' then
                result['version'] = true
                return
            end
            if option == '--verbose' or option == '-v' then
                result['verbosity'] = VERBOSITY_VERBOSE
                return
            end
            if option == '--quiet' or option == '-q' then
                result['verbosity'] = VERBOSITY_QUIET
                return
            end
            if option == '--output' or option == '-o' then
                state = SET_OUTPUT
                return state
            end
            if option == '--name' or option == '-n' then
                state = SET_FNAME
                return state
            end
            if option == '--pattern' or option == '-p' then
                state = SET_PATTERN
                return state
            end
            error('Unknown option: '..option,3)
        end

        local function setArg( cmdArg, state )
            if state == SET_OUTPUT then
                result['output'] = cmdArg
                return
            end
            if state == SET_FNAME then
                result['fname'] = cmdArg
                return
            end
            if state == SET_PATTERN then
                if result['pattern'] then
                    table.insert( result['pattern'], cmdArg )
                else
                    result['pattern'] = { cmdArg }
                end
                return
            end
            error('Unknown parse state: '.. state)
        end


        for i, cmdArg in ipairs(cmdLine) do
            if state ~= nil then
                setArg( cmdArg, state, result )
                state = nil
            else 
                if cmdArg:sub(1,1) == '-' then
                    state = parseOption( cmdArg )
                else 
                    if result['testNames'] then
                        table.insert( result['testNames'], cmdArg )
                    else
                        result['testNames'] = { cmdArg }
                    end
                end
            end
        end

        if result['help'] then
            LuaUnit.help()
        end

        if result['version'] then
            LuaUnit.version()
        end

        if state ~= nil then
            error('Missing argument after '..cmdLine[ #cmdLine ],2 )
        end

        return result
    end

    function LuaUnit.help()
        print(USAGE)
        os.exit(0)
    end

    function LuaUnit.version()
        print('LuaUnit v'..VERSION..' by Philippe Fremy <phil@freehackers.org>')
        os.exit(0)
    end

    function LuaUnit.patternInclude( patternFilter, expr )
        -- check if any of patternFilter is contained in expr. If so, return true.
        -- return false if None of the patterns are contained in expr
        -- if patternFilter is nil, return true (no filtering)
        if patternFilter == nil then
            return true
        end

        for i,pattern in ipairs(patternFilter) do
            if string.find(expr, pattern) then
                return true
            end
        end

        return false
    end

    --------------[[ Output methods ]]-------------------------

    NodeStatus = { -- class
        __class__ = 'NodeStatus',
        number = 0,
        testName = '',
        className = '',

        hasFailure = function(self)
            -- print('hasFailure: '..prettystr(self))
            return (self.execStatus ~= nil) and (self.execStatus.status == STATUS_FAIL)
        end
    }
    NodeStatus_MT = { __index = NodeStatus }

    function NodeStatus:new( number, testName, className )
        local t = {}
        t.number = number
        t.testName = testName
        t.className = className
        -- useless but we know it's the field we want to use
        t.execStatus = nil
        setmetatable( t, NodeStatus_MT )
        return t
    end

    STATUS_PASS='pass'
    STATUS_FAIL='fail'

    function LuaUnit:startSuite(testCount, nonSelectedCount)
        self.result = {}
        self.result.failureCount = 0
        self.result.testCount = testCount
        self.result.nonSelectedCount = nonSelectedCount
        self.result.currentTestNumber = 0
        self.result.currentClassName = ""
        self.result.currentNode = nil
        self.result.suiteStarted = true
        self.result.startTime = os.clock()
        self.result.startDate = os.date()
        self.result.startIsodate = os.date('%Y-%m-%dT%H-%M-%S')
        self.result.patternFilter = self.patternFilter
        self.result.tests = {}
        self.outputType = self.outputType or TextOutput
        self.output = self.outputType:new()
        self.output.runner = self
        self.output.result = self.result
        self.output.verbosity = self.verbosity
        self.output.fname = self.fname
        self.output:startSuite()
    end

    function LuaUnit:startClass( className )
        self.result.currentClassName = className
        self.output:startClass( className )
    end

    function LuaUnit:startTest( testName  )
        self.result.currentTestNumber = self.result.currentTestNumber + 1
        self.result.currentNode = NodeStatus:new(
            self.result.currentTestNumber,
            testName,
            self.result.currentClassName
        )
        table.insert( self.result.tests, self.currentNode )
        self.output:startTest( testName )
    end

    function LuaUnit:addFailure( errorMsg, stackTrace )
        if self.result.currentNode.execStatus == nil then
            self.result.failureCount = self.result.failureCount + 1
            self.result.currentNode.execStatus = {
                status = STATUS_FAIL,
                msg = errorMsg,
                stackTrace = stackTrace
            }
        end
        self.output:addFailure( errorMsg, stackTrace )
    end

    function LuaUnit:endTest()
        -- print( 'endTEst() '..prettystr(self.result.currentNode))
        -- print( 'endTEst() '..prettystr(self.result.currentNode:hasFailure()))
        self.output:endTest( self.result.currentNode:hasFailure() )
        self.result.currentNode = nil
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
        error( 'No such format: '..outputType,2)
    end

    function LuaUnit:setVerbosity( verbosity )
        self.verbosity = verbosity
    end

    function LuaUnit:setFname( fname )
        self.fname = fname
    end

    --------------[[ Runner ]]-----------------

    SPLITTER = '\n>----------<\n'

    function LuaUnit:protectedCall( classInstance , methodInstance, prettyFuncName)
        -- if classInstance is nil, this is just a function run
        local function err_handler(e)
            return debug.traceback(e..SPLITTER, 3)
        end

        local ok=true, fullErrMsg, stackTrace, errMsg
        if classInstance then
            -- stupid Lua < 5.2 does not allow xpcall with arguments so let's use a workaround
            ok, fullErrMsg = xpcall( function () methodInstance(classInstance) end, err_handler )
        else
            ok, fullErrMsg = xpcall( function () methodInstance() end, err_handler )
        end
        if ok then
            return ok
        end

        t = strsplit( SPLITTER, fullErrMsg )
        errMsg = t[1]
        stackTrace = string.sub(t[2],2)
        if methodName then
            -- we do have the real method name, improve the stack trace
            stackTrace = string.gsub( stackTrace, "in function 'methodInstance'", "in function '"..prettyFuncName.."'")
        end

        return ok, errMsg, stackTrace
    end


    function LuaUnit:execOneFunction(className, methodName, classInstance, methodInstance)
        -- When executing a test function, className and classInstance must be nil
        -- When executing a class method, all parameters must be set

        local ok, errMsg, stackTrace

        if type(methodInstance) ~= 'function' then
            error( tostring(methodName)..' must be a function, not '..type(methodInstance))
        end

        if className == nil then
            className = '[TestFunctions]'
            prettyFuncName = methodName
        else
            prettyFuncName = className..'.'..methodName
        end

        if self.lastClassName ~= className then
            if self.lastClassName ~= nil then
                self:endClass()
            end
            self:startClass( className )
            self.lastClassName = className
        end

        self:startTest(prettyFuncName)

        -- run setUp first(if any)
        if classInstance and self.isFunction( classInstance.setUp ) then
            ok, errMsg, stackTrace = self:protectedCall( classInstance, classInstance.setUp, className..'.setUp')
            if not ok then
                self:addFailure( errMsg, stackTrace )
            end
        end

        -- run testMethod()
        if not self.result.currentNode:hasFailure() then
            ok, errMsg, stackTrace = self:protectedCall( classInstance, methodInstance, prettyFuncName)
            if not ok then
                self:addFailure( errMsg, stackTrace )
            end
        end

        -- lastly, run tearDown(if any)
        if classInstance and self.isFunction(classInstance.tearDown) then
            ok, errMsg, stackTrace = self:protectedCall( classInstance, classInstance.tearDown, className..'.tearDown')
            if not ok then
                self:addFailure( errMsg, stackTrace )
            end
        end

        self:endTest()
    end

    function LuaUnit.expandOneClass( result, className, classInstance )
        -- add all test methods of classInstance to result
        for methodName, methodInstance in sortedPairs(classInstance) do
            if LuaUnit.isFunction(methodInstance) and LuaUnit.isMethodTestName( methodName ) then
                table.insert( result, { className..'.'..methodName, classInstance } )
            end
        end
    end

    function LuaUnit.expandClasses( listOfNameAndInst )
        -- expand all classes (proveded as {className, classInstance}) to a list of {className.methodName, classInstance}
        -- functions and methods remain untouched
        local result = {}

        for i,v in ipairs( listOfNameAndInst ) do
            name, instance = v[1], v[2]
            if LuaUnit.isFunction(instance) then
                table.insert( result, { name, instance } )
            else 
                if type(instance) ~= 'table' then
                    error( 'Instance must be a table or a function, not a '..type(instance)..', value '..prettystr(instance))
                end
                if LuaUnit.isClassMethod( name ) then
                    className, instanceName = LuaUnit.splitClassMethod( name )
                    methodInstance = instance[methodName]
                    if methodInstance == nil then
                        error( "Could not find method in class "..tostring(className).." for method "..tostring(methodName) )
                    end
                    table.insert( result, { name, instance } )
                else
                    LuaUnit.expandOneClass( result, name, instance )
                end
            end
        end

        return result
    end

    function LuaUnit.applyPatternFilter( patternFilter, listOfNameAndInst )
        local included = {}
        local excluded = {}

        for i,v in ipairs( listOfNameAndInst ) do
            name, instance = v[1], v[2]

            if patternFilter and not LuaUnit.patternInclude( patternFilter, name ) then
                table.insert( excluded, v )
            else
                table.insert( included, v )
            end
        end
        return included, excluded

    end

    function LuaUnit:runSuiteByInstances( listOfNameAndInst )
        -- Run an explicit list of tests. All test instances and names must be supplied.
        -- each test must be one of:
        --   * { function name, function instance }
        --   * { class name, class instance }
        --   * { class.method name, class instance }

        expandedList = self.expandClasses( listOfNameAndInst )

        filteredList, filteredOutList = self.applyPatternFilter( self.patternFilter, expandedList )

        self:startSuite( #filteredList, #filteredOutList )

        for i,v in ipairs( filteredList ) do
            name, instance = v[1], v[2]
            if LuaUnit.isFunction(instance) then
                self:execOneFunction( nil, name, nil, instance )
            else 
                if type(instance) ~= 'table' then
                    error( 'Instance must be a table or a function, not a '..type(instance)..', value '..prettystr(instance))
                else
                    assert( LuaUnit.isClassMethod( name ) )
                    className, instanceName = LuaUnit.splitClassMethod( name )
                    methodInstance = instance[methodName]
                    if methodInstance == nil then
                        error( "Could not find method in class "..tostring(className).." for method "..tostring(methodName) )
                    end
                    self:execOneFunction( className, methodName, instance, methodInstance )
                end
            end
        end

        if self.lastClassName ~= nil then
            self:endClass()
        end

        self:endSuite()
    end

    function LuaUnit:runSuiteByNames( listOfName )
        -- Run an explicit list of test names

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

    function LuaUnit.run(...)
        -- Run some specific test classes.
        -- If no arguments are passed, run the class names specified on the
        -- command line. If no class name is specified on the command line
        -- run all classes whose name starts with 'Test'
        --
        -- If arguments are passed, they must be strings of the class names 
        -- that you want to run or generic command line arguments (-o, -p, -v, ...)

        local runner = LuaUnit.new()
        return runner:runSuite(...)
    end

    function LuaUnit:runSuite( ... )

        local args={...};
        if args[1] ~= nil and type(args[1]) == 'table' and args[1].__class__ == 'LuaUnit' then
            -- run was called with the syntax LuaUnit:runSuite()
            -- we support both LuaUnit.run() and LuaUnit:run()
            -- strip out the first argument
            table.remove(args,1)
        end

        if #args == 0 then
            args = cmdline_argv
        end

        local no_error, error_msg, options, val
        no_error, val = pcall( LuaUnit.parseCmdLine, args )
        if not no_error then 
            error_msg = val
            print(error_msg)
            print()
            print(USAGE)
            os.exit(-1)
        end 

        options = val

        if options.verbosity then
            self:setVerbosity( options.verbosity )
        end

        if options.output and options.output:lower() == 'junit' and options.fname == nil then
            print('With junit output, a filename must be supplied with -n or --name')
            os.exit(-1)
        end

        if options.output then
            no_error, val = pcall(self.setOutputType,self,options.output)
            if not no_error then 
                error_msg = val
                print(error_msg)
                print()
                print(USAGE)
                os.exit(-1)
            end 
        end

        if options.fname then
            self:setFname( options.fname )
        end

        if options.pattern then
            self.patternFilter = options.pattern
        end

        testNames = options['testNames']

        if testNames == nil then
            testNames = LuaUnit.collectTests()
        end

        self:runSuiteByNames( testNames )

        return self.result.failureCount
    end

-- class LuaUnit
