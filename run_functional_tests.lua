#!/usr/bin/env lua

require('os')
lu = require('luaunit')


function report( s )
    print('>>>>>>> '..s )
end

local IS_UNIX = ( package.config:sub(1,1) == '/' )
local LUA='"'..arg[-1]..'"'


-- This function is extracted from the lua Nucleo project.
-- License is MIT so ok to reuse here
-- https://github.com/lua-nucleo/lua-nucleo/blob/v0.1.0/lua-nucleo/string.lua#L245-L267
local escape_lua_pattern
do
  local matches =
  {
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
    ["\0"] = "%z";
  }

  escape_lua_pattern = function(s)
    return (s:gsub(".", matches))
  end
end

function string_sub(s, orig, repl)
    -- replace occurence of string orig by string repl
    -- just like string.gsub, but with no pattern matching
    safeOrig = escape_lua_pattern(orig)
    return string.gsub( s, safeOrig, repl )
end

function testStringSub()
    lu.assertEquals( string_sub('aa a % b cc', 'a % b', 'a + b'), 'aa a + b cc' )
    lu.assertEquals( string_sub('aa: ?cc', ': ?', 'xx?'), 'aaxx?cc' )
end

function osExec( s )
    -- execute s with os.execute and return true if exit code is 0
    -- false in any other conditions

    -- print('osExec('..s..')')
    local exitSuccess, exitReason, exitCode 
    exitSuccess, exitReason, exitCode = os.execute( s )
    -- print(exitSuccess)
    -- print(exitReason)
    -- print(exitCode)

    if _VERSION == 'Lua 5.1' then
        -- Lua 5.1 returns only the exit code
        exitReason = 'exit'
        if IS_UNIX then
            -- in C:  exitCode = (exitSuccess >> 8) & 0xFF
            -- poor approximation that works:
            exitCode = (exitSuccess / 256)
        else
            -- Windows, life is simple
            exitCode = exitSuccess
        end
    end

    if exitReason ~= 'exit' or exitCode ~= 0 then
        -- print('return false '..tostring(exitCode))
        return false, exitCode
    end

    -- print('return true')
    return true, exitCode
end

local HAS_XMLLINT 
do
    xmllint_output_fname = 'test/has_xmllint.txt'
    HAS_XMLLINT = osExec('xmllint --version 2> '..xmllint_output_fname)
    if not HAS_XMLLINT then
        report('WARNING: xmllint absent, can not validate xml validity')
    end
    os.remove(xmllint_output_fname)
end

function adjustFile( fileOut, fileIn, pattern, mayBeAbsent, verbose )
    --[[ Adjust the content of fileOut by copying lines matching pattern from fileIn

    fileIn lines are read and the first line matching pattern is analysed. The first pattern
    capture is memorized.

    fileOut lines are then read, and the first line matching pattern is modified, by applying
    the first capture of fileIn. fileOut is then rewritten.
    ]]
    local source = nil
    mayBeAbsent = mayBeAbsent or false
    for line in io.lines(fileIn) do
        local idxStart, idxEnd, capture = string.find( line, pattern )
        if idxStart ~= nil then
            if capture == nil then
                error(string.format('Must specify a capture for pattern %s in function adjustFile()', pattern ) )
            end
            source = capture
            break
        end
    end

    if source == nil then
        if mayBeAbsent == true then
            -- no capture, just return
            return
        end
        error('No line in file '..fileIn..' matching pattern "'..pattern..'"')
    end

    if verbose then
        print('Captured in source: '.. source )
    end

    local dest = nil
    local linesOut = {}
    for line in io.lines(fileOut) do
        local idxStart, idxEnd, capture = string.find( line, pattern )
        if idxStart ~= nil then
            dest = capture
            if verbose then
                print('Modifying line: '..line )
            end
            line = string_sub(line, dest, source)
            -- line = line:sub(1,idxStart-1)..source..line:sub(idxEnd+1)
            -- string.gsub( line, dest, source )
            if verbose then
                print('Result: '..line )
            end
        end
        table.insert( linesOut, line )
    end

    if dest == nil then
        if mayBeAbsent == true then
            -- capture but nothing to adjust, just return
            return
        end
        error('No line in file '..fileOut..' matching pattern "'..pattern..'"' )
    end

    f = io.open( fileOut, 'w')
    for i,l in ipairs(linesOut) do
        f:write( l..'\n' )
    end
    f:close()

end

function check_tap_output( fileToRun, options, output, refOutput, refExitCode )
    local ret
    -- remove output
    ret, exitCode = osExec(string.format(
            '%s %s  --output TAP %s > %s', LUA, fileToRun, options, output )  )

    if refExitCode ~= nil and exitCode ~= refExitCode then
        error(string.format('Expected exit code %d but got %d for file %s', refExitCode, exitCode, fileToRun ) )
    end

    adjustFile( output, refOutput, '# Started on (.*)')
    adjustFile( output, refOutput, '# Ran %d+ tests in (%d+.%d*).*')
    if options == '--verbose' then
        -- For Lua 5.1 / 5.2 compatibility
        adjustFile( output, refOutput, '(%s+%[C%]: i?n? ?%?)', true )
    end
    -- For Lua 5.3: stack trace uses "method" instead of "function"
    adjustFile( output, refOutput, '.*%.lua:%d+: in (%S*) .*', true, false )

    ret = osExec( string.format([[diff -NPw -u  -I " *\.[/\\]luaunit.lua:[0123456789]\+:.*" %s %s]], refOutput, output ) )
    if not ret then
        error('TAP Output mismatch for file : '..output)
    end
    -- report('TAP Output ok: '..output)
    return 0
end


function check_text_output( fileToRun, options, output, refOutput, refExitCode )
    local ret
    -- remove output
    ret, exitCode = osExec(string.format(
            '%s %s  --output text %s > %s', LUA, fileToRun, options, output )  )

    if refExitCode ~= nil and exitCode ~= refExitCode then
        error(string.format('Expected exit code %d but got %d for file %s', refExitCode, exitCode, fileToRun ) )
    end

    if options == '--verbose' then
        adjustFile( output, refOutput, 'Started on (.*)')
    end
    adjustFile( output, refOutput, 'Ran .* tests in (%d.%d*) seconds' )
    if options ~= '--quiet' then
        -- For Lua 5.1 / 5.2 compatibility
        adjustFile( output, refOutput, '(%s+%[C%]: i?n? ?%?)', true )
    end
    -- For Lua 5.3: stack trace uses "method" instead of "function"
    adjustFile( output, refOutput, '.*%.lua:%d+: in (%S*) .*', true, false )
 

    ret = osExec( string.format([[diff -NPw -u  -I " *\.[/\\]luaunit.lua:[0123456789]\+:.*" %s %s]], refOutput, output ) )
    if not ret then
        error('Text Output mismatch for file : '..output)
        return 1
    end
    -- report('Text Output ok: '..output)
    return 0
end

function check_nil_output( fileToRun, options, output, refOutput, refExitCode )
    local ret
    -- remove output
    ret, exitCode = osExec(string.format(
            '%s %s  --output nil %s > %s', LUA, fileToRun, options, output )  )

    if refExitCode ~= nil and exitCode ~= refExitCode then
        error(string.format('Expected exit code %d but got %d for file %s', refExitCode, exitCode, fileToRun ) )
    end

    ret = osExec( string.format([[diff -NPw -u  -I " *\.[/\\]luaunit.lua:[0123456789]\+:.*" %s %s]], refOutput, output ) )
    if not ret then
        error('NIL Output mismatch for file : '..output)
    end
    -- report('NIL Output ok: '..output)
    return 0
end

function check_xml_output( fileToRun, options, output, xmlOutput, xmlLintOutput, refOutput, refXmlOutput, refExitCode )
    local ret, retcode
    retcode = 0

    -- remove output
    ret, exitCode = osExec(string.format(
            '%s %s %s --output junit --name %s > %s', LUA, fileToRun, options, xmlOutput, output )  )

    if refExitCode ~= nil and exitCode ~= refExitCode then
        error(string.format('Expected exit code %d but got %d for file %s', refExitCode, exitCode, fileToRun ) )
    end

    adjustFile( output, refOutput, '# XML output to (.*)')
    adjustFile( output, refOutput, '# Started on (.*)')
    adjustFile( output, refOutput, '# Ran %d+ tests in (%d+.%d*).*')
    adjustFile( xmlOutput, refXmlOutput, '.*<testsuite.*(timestamp=".-" time=".-").*')
    -- neutralize all testcase time values in ref xml output
    adjustFile( refXmlOutput, refXmlOutput, '.*<testcase .*(time=".-").*' )
    adjustFile( xmlOutput, refXmlOutput, '.*<testcase .*(time=".-").*' )
    -- For Lua 5.1 / 5.2 compatibility
    adjustFile( xmlOutput, refXmlOutput, '.*<property name="Lua Version" value="(Lua 5..)"/>')
    adjustFile( output, refOutput, '(.+%[C%]: i?n? ?%?)', true )
    adjustFile( xmlOutput, refXmlOutput, '(.+%[C%]: i?n? ?%?.*)', true )
    -- For Lua 5.3: stack trace uses "method" instead of "function"
    adjustFile( output, refOutput, '.*%.lua:%d+: in (%S*) .*', true, false )
    adjustFile( xmlOutput, refXmlOutput, '.*%.lua:%d+: in (%S*) .*', true, false )


    if HAS_XMLLINT then
        -- General xmllint validation
        ret = osExec( string.format('xmllint --noout %s > %s', xmlOutput, xmlLintOutput ) )
        if ret then
            -- report(string.format('XMLLint validation ok: file %s', xmlLintOutput) )
        else
            error(string.format('XMLLint reported errors : file %s', xmlLintOutput) )
            retcode = retcode + 1
        end

        -- Validation against apache junit schema
        ret = osExec( string.format('xmllint --noout --schema junitxml/junit-apache-ant.xsd %s 2> %s', xmlOutput, xmlLintOutput ) )
        if ret then
            -- report(string.format('XMLLint validation ok: file %s', xmlLintOutput) )
        else
            error(string.format('XMLLint reported errors against apache schema: file %s', xmlLintOutput) )
            retcode = retcode + 1
        end

        -- Validation against jenkins/hudson schema
        ret = osExec( string.format('xmllint --noout --schema junitxml/junit-jenkins.xsd %s 2> %s', xmlOutput, xmlLintOutput ) )
        if ret then
            -- report(string.format('XMLLint validation ok: file %s', xmlLintOutput) )
        else
            error(string.format('XMLLint reported errors against apache schema: file %s', xmlLintOutput) )
            retcode = retcode + 1
        end

    end

    -- ignore change in line numbers for luaunit
    ret = osExec( string.format([[diff -NPw -u -I " *\.[/\\]luaunit.lua:[0123456789]\+:.*" %s %s]], refXmlOutput, xmlOutput ) )
    if not ret then
        error('XML content mismatch for file : '..xmlOutput)
        retcode = retcode + 1
    end

    ret = osExec( string.format([[diff -NPw -u  -I " *\.[/\\]luaunit.lua:[0123456789]\+:.*" %s %s]], refOutput, output ) )
    if not ret then
        error('XML Output mismatch for file : '..output)
        retcode = retcode + 1
    end

    if retcode == 0 then
        -- report('XML Output ok: '..output)
    end

    return retcode
end

-- check tap output

function testTapDefault()
    lu.assertEquals( 0,
        check_tap_output('example_with_luaunit.lua', '',          'test/exampleTapDefault.txt', 'test/ref/exampleTapDefault.txt', 12) )
    lu.assertEquals( 0,
        check_tap_output('run_unit_tests.lua', '',          'test/unitTestsTapDefault.txt', 'test/ref/unitTestsTapDefault.txt', 0 ) )
end

function testTapVerbose()
    lu.assertEquals( 0,
        check_tap_output('example_with_luaunit.lua', '--verbose', 'test/exampleTapVerbose.txt', 'test/ref/exampleTapVerbose.txt', 12 ) )
    lu.assertEquals( 0,
        check_tap_output('run_unit_tests.lua', '--verbose', 'test/unitTestsVerbose.txt', 'test/ref/unitTestsTapVerbose.txt', 0 ) )
end

function testTapQuiet()
    lu.assertEquals( 0,
        check_tap_output('example_with_luaunit.lua', '--quiet',   'test/exampleTapQuiet.txt',   'test/ref/exampleTapQuiet.txt', 12 ) )
    lu.assertEquals( 0,
        check_tap_output('run_unit_tests.lua', '--quiet',   'test/unitTestsTapQuiet.txt',   'test/ref/unitTestsTapQuiet.txt', 0 ) )
end

-- check text output

function testTextDefault()
    lu.assertEquals( 0,
        check_text_output('example_with_luaunit.lua', '',          'test/exampleTextDefault.txt', 'test/ref/exampleTextDefault.txt', 12 ) )
    lu.assertEquals( 0,
        check_text_output('run_unit_tests.lua', '',          'test/unitTestsTextDefault.txt', 'test/ref/unitTestsTextDefault.txt', 0 ) )
end

function testTextVerbose()
    lu.assertEquals( 0,
        check_text_output('example_with_luaunit.lua', '--verbose', 'test/exampleTextVerbose.txt', 'test/ref/exampleTextVerbose.txt', 12 ) )
    lu.assertEquals( 0,
        check_text_output('run_unit_tests.lua', '--verbose', 'test/unitTestsTextVerbose.txt', 'test/ref/unitTestsTextVerbose.txt', 0 ) )
end

function testTextQuiet()
    lu.assertEquals( 0,
        check_text_output('example_with_luaunit.lua', '--quiet',   'test/exampleTextQuiet.txt',   'test/ref/exampleTextQuiet.txt', 12 ) )
    lu.assertEquals( 0,
        check_text_output('run_unit_tests.lua', '--quiet',   'test/unitTestsTextQuiet.txt',   'test/ref/unitTestsTextQuiet.txt', 0 ) )
end

-- check nil output

function testNilDefault()
    lu.assertEquals( 0,
        check_nil_output('example_with_luaunit.lua', '', 'test/exampleNilDefault.txt', 'test/ref/exampleNilDefault.txt', 12 ) )
    lu.assertEquals( 0,
        check_nil_output('run_unit_tests.lua', '', 'test/unitTestseNilDefault.txt', 'test/ref/unitTestsNilDefault.txt', 0 ) )
end

-- check xml output

function testXmlDefault()
    lu.assertEquals( 0,
        check_xml_output('example_with_luaunit.lua', '',          'test/exampleXmlDefault.txt', 'test/exampleXmlDefault.xml',
        'test/exampleXmllintDefault.xml', 'test/ref/exampleXmlDefault.txt', 'test/ref/exampleXmlDefault.xml', 12 ) )
    lu.assertEquals( 0,
        check_xml_output('run_unit_tests.lua', '',          'test/unitTestsXmlDefault.txt', 'test/unitTestsXmlDefault.xml',
        'test/unitTestsXmllintDefault.xml', 'test/ref/unitTestsXmlDefault.txt', 'test/ref/unitTestsXmlDefault.xml', 0 ) )
end

function testXmlVerbose()
    lu.assertEquals( 0,
        check_xml_output('example_with_luaunit.lua', '--verbose', 'test/exampleXmlVerbose.txt', 'test/exampleXmlVerbose.xml',
        'test/exampleXmllintVerbose.xml', 'test/ref/exampleXmlVerbose.txt', 'test/ref/exampleXmlVerbose.xml', 12 ) )
    lu.assertEquals( 0,
        check_xml_output('run_unit_tests.lua', '--verbose', 'test/unitTestsXmlVerbose.txt', 'test/unitTestsXmlVerbose.xml',
        'test/unitTestsXmllintVerbose.xml', 'test/ref/unitTestsXmlVerbose.txt', 'test/ref/unitTestsXmlVerbose.xml', 0 ) )
end

function testXmlQuiet()
    lu.assertEquals( 0,
        check_xml_output('example_with_luaunit.lua', '--quiet',   'test/exampleXmlQuiet.txt', 'test/exampleXmlQuiet.xml',
        'test/exampleXmllintQuiet.xml', 'test/ref/exampleXmlQuiet.txt', 'test/ref/exampleXmlQuiet.xml', 12 ) )
    lu.assertEquals( 0,
        check_xml_output('run_unit_tests.lua', '--quiet',   'test/unitTestsXmlQuiet.txt', 'test/unitTestsXmlQuiet.xml',
        'test/unitTestsXmllintQuiet.xml', 'test/ref/unitTestsXmlQuiet.txt', 'test/ref/unitTestsXmlQuiet.xml', 0 ) )
end

function testTestXmlDefault()
    if _VERSION == 'Lua 5.1' then
        -- this test differs slightly in Lua 5.1 and 5.2
        -- I did not manage to adjust the "(...tail call...)" printed differently in Lua 5.2 vs 5.1
        lu.assertEquals( 0,
            check_xml_output('test/test_with_xml.lua', '', 'test/testWithXmlDefault51.txt', 'test/testWithXmlDefault51.xml',
            'test/testWithXmlLintDefault51.txt', 'test/ref/testWithXmlDefault51.txt', 'test/ref/testWithXmlDefault51.xml', 2 ) )
    else
        lu.assertEquals( 0,
            check_xml_output('test/test_with_xml.lua', '', 'test/testWithXmlDefault.txt', 'test/testWithXmlDefault.xml',
            'test/testWithXmlLintDefault.txt', 'test/ref/testWithXmlDefault.txt', 'test/ref/testWithXmlDefault.xml', 2 ) )
    end
end

function testTestXmlVerbose()
    if _VERSION == 'Lua 5.1' then
        lu.assertEquals( 0,
            check_xml_output('test/test_with_xml.lua', '--verbose', 'test/testWithXmlVerbose51.txt', 'test/testWithXmlVerbose51.xml',
            'test/testWithXmlLintVerbose51.txt', 'test/ref/testWithXmlVerbose51.txt', 'test/ref/testWithXmlVerbose51.xml', 2 ) )
    else
        lu.assertEquals( 0,
            check_xml_output('test/test_with_xml.lua', '--verbose', 'test/testWithXmlVerbose.txt', 'test/testWithXmlVerbose.xml',
            'test/testWithXmlLintVerbose.txt', 'test/ref/testWithXmlVerbose.txt', 'test/ref/testWithXmlVerbose.xml', 2 ) )
    end
end

function testTestXmlQuiet()
    if _VERSION == 'Lua 5.1' then
        lu.assertEquals( 0,
            check_xml_output('test/test_with_xml.lua', '--quiet', 'test/testWithXmlQuiet51.txt', 'test/testWithXmlQuiet51.xml',
            'test/testWithXmlLintQuiet51.txt', 'test/ref/testWithXmlQuiet51.txt', 'test/ref/testWithXmlQuiet51.xml', 2 ) )
    else
        lu.assertEquals( 0,
            check_xml_output('test/test_with_xml.lua', '--quiet', 'test/testWithXmlQuiet.txt', 'test/testWithXmlQuiet.xml',
            'test/testWithXmlLintQuiet.txt', 'test/ref/testWithXmlQuiet.txt', 'test/ref/testWithXmlQuiet.xml', 2 ) )
    end
end

function testLegacyLuaunitUsage()
    -- run test/legacy_example_usage and check exit status
    local ret, exitCode, refExitCode, fileToRun
    fileToRun = "test/legacy_example_with_luaunit.lua"
    fileOutput = "test/legacyExample.txt"
    refExitCode = 12
    ret, exitCode = osExec(string.format( '%s %s  --output text > %s', LUA,  fileToRun, fileOutput)  )


    if refExitCode ~= nil and exitCode ~= refExitCode then
        error(string.format('Expected exit code %d but got %d for file %s', refExitCode, exitCode, fileToRun ) )
    end 

end

filesToGenerateExampleXml = {
    { 'example_with_luaunit.lua', '', '--output junit --name test/ref/exampleXmlDefault.xml', 'test/ref/exampleXmlDefault.txt' },
    { 'example_with_luaunit.lua', '--quiet', '--output junit --name test/ref/exampleXmlQuiet.xml', 'test/ref/exampleXmlQuiet.txt' },
    { 'example_with_luaunit.lua', '--verbose', '--output junit --name test/ref/exampleXmlVerbose.xml', 'test/ref/exampleXmlVerbose.txt' },
}

filesToGenerateExampleTap = {
    { 'example_with_luaunit.lua', '', '--output tap', 'test/ref/exampleTapDefault.txt' },
    { 'example_with_luaunit.lua', '--quiet', '--output tap', 'test/ref/exampleTapQuiet.txt' },
    { 'example_with_luaunit.lua', '--verbose', '--output tap', 'test/ref/exampleTapVerbose.txt' },
}

filesToGenerateExampleText = {
    { 'example_with_luaunit.lua', '', '--output text', 'test/ref/exampleTextDefault.txt' },
    { 'example_with_luaunit.lua', '--quiet', '--output text', 'test/ref/exampleTextQuiet.txt' },
    { 'example_with_luaunit.lua', '--verbose', '--output text', 'test/ref/exampleTextVerbose.txt' },
}

filesToGenerateExampleNil = {
    { 'example_with_luaunit.lua', '', '--output nil', 'test/ref/exampleNilDefault.txt' },
}

filesToGenerateUnitXml = {
    { 'run_unit_tests.lua', '', '--output junit --name test/ref/unitTestsXmlDefault.xml', 'test/ref/unitTestsXmlDefault.txt' },
    { 'run_unit_tests.lua', '--quiet', '--output junit --name test/ref/unitTestsXmlQuiet.xml', 'test/ref/unitTestsXmlQuiet.txt' },
    { 'run_unit_tests.lua', '--verbose', '--output junit --name test/ref/unitTestsXmlVerbose.xml', 'test/ref/unitTestsXmlVerbose.txt' },
}

filesToGenerateUnitTap = {
    { 'run_unit_tests.lua', '', '--output tap', 'test/ref/unitTestsTapDefault.txt' },
    { 'run_unit_tests.lua', '--quiet', '--output tap', 'test/ref/unitTestsTapQuiet.txt' },
    { 'run_unit_tests.lua', '--verbose', '--output tap', 'test/ref/unitTestsTapVerbose.txt' },
}

filesToGenerateUnitText = {
    { 'run_unit_tests.lua', '', '--output text', 'test/ref/unitTestsTextDefault.txt' },
    { 'run_unit_tests.lua', '--quiet', '--output text', 'test/ref/unitTestsTextQuiet.txt' },
    { 'run_unit_tests.lua', '--verbose', '--output text', 'test/ref/unitTestsTextVerbose.txt' },
}

filesToGenerateTestXml = {}
if _VERSION == 'Lua 5.1' then
    table.insert( filesToGenerateTestXml, { 'test/test_with_xml.lua', '', '--output junit --name test/ref/testWithXmlDefault51.xml', 'test/ref/testWithXmlDefault51.txt' } )
    table.insert( filesToGenerateTestXml, { 'test/test_with_xml.lua', '--verbose', '--output junit --name test/ref/testWithXmlVerbose51.xml', 'test/ref/testWithXmlVerbose51.txt' } )
    table.insert( filesToGenerateTestXml, { 'test/test_with_xml.lua', '--quiet', '--output junit --name test/ref/testWithXmlQuiet51.xml', 'test/ref/testWithXmlQuiet51.txt' } )
else
    table.insert( filesToGenerateTestXml, { 'test/test_with_xml.lua', '', '--output junit --name test/ref/testWithXmlDefault.xml', 'test/ref/testWithXmlDefault.txt' } )
    table.insert( filesToGenerateTestXml, { 'test/test_with_xml.lua', '--verbose', '--output junit --name test/ref/testWithXmlVerbose.xml', 'test/ref/testWithXmlVerbose.txt' } )
    table.insert( filesToGenerateTestXml, { 'test/test_with_xml.lua', '--quiet', '--output junit --name test/ref/testWithXmlQuiet.xml', 'test/ref/testWithXmlQuiet.txt' } )
end

filesSetIndex = {
    UnitText=filesToGenerateUnitText,
    UnitTap=filesToGenerateUnitTap,
    UnitXml=filesToGenerateUnitXml,
    ExampleNil=filesToGenerateExampleNil,
    ExampleText=filesToGenerateExampleText,
    ExampleTap=filesToGenerateExampleTap,
    ExampleXml=filesToGenerateExampleXml,
    TestXml=filesToGenerateTestXml,
}



function updateRefFiles( filesToGenerate )
    local ret

    for i,v in ipairs(filesToGenerate) do 
        report('Generating '..v[4])
        ret = osExec( string.format('%s %s %s %s > %s', LUA, v[1], v[2], v[3], v[4]) )
        --[[
        -- exitcode != 0 is not an error for us ...
        if ret == false then
            error('Error while generating '..prettystr(v) )
            os.exit(1)
        end
        ]]
    end
end


function main()
    if arg[1] == '--update' then
        if #arg == 1 then
            -- generate all files
            -- print('Generating all files' )
            for k,v in pairs(filesSetIndex) do 
                -- print('Generating '..v )
                updateRefFiles( v )
            end
        else
            -- generate subset of files
            local i=2
            while i <=  #arg do
                fileSet = filesSetIndex[ arg[i] ]
                if fileSet == nil then
                    local validTarget = ''
                    for k,v in pairs(filesSetIndex) do
                        validTarget = validTarget .. ' '.. k
                    end
                    error(string.format('Unable to generate files for target %s\nPossible targets: %s\n', arg[i], validTarget) )
                end
                -- print('Generating '..arg[i])
                updateRefFiles( fileSet )
                i = i + 1
            end
        end
        os.exit(0)
    end

    os.exit( lu.LuaUnit.run() )
    -- body
end

main()

-- TODO check output of run_unit_tests
-- TODO check return values of execution


