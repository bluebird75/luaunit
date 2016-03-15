#!/usr/bin/env lua

require('os')
lu = require('luaunit')


function report( ... )
    print('>>>>>>>', string.format(...))
end

function error_fmt( ... )
    error(string.format(...), 2) -- (level 2 = report chunk calling error_fmt)
end

local IS_UNIX = ( package.config:sub(1,1) == '/' )
local LUA='"'..arg[-1]..'"'


-- Escape a string so it can safely be used as a Lua pattern without triggering
-- special semantics. This means prepending any "magic" character ^$()%.[]*+-?
-- with a percent sign. Note: We DON'T expect embedded NUL chars, and thus
-- won't escape those (%z) for Lua 5.1.
local LUA_MAGIC_CHARS = "[%^%$%(%)%%%.%[%]%*%+%-%?]"
function escape_lua_pattern(s)
    return s:gsub(LUA_MAGIC_CHARS, "%%%1") -- substitute with '%' + matched char
end

function string_sub(s, orig, repl)
    -- replace occurrence of string orig by string repl
    -- just like string.gsub, but with no pattern matching
    return s:gsub( escape_lua_pattern(orig), repl )
end

function testStringSub()
    lu.assertEquals( string_sub('aa a % b cc', 'a % b', 'a + b'), 'aa a + b cc' )
    lu.assertEquals( string_sub('aa: ?cc', ': ?', 'xx?'), 'aaxx?cc' )
end

function osExec( ... )
    -- execute a command with os.execute and return true if exit code is 0
    -- false in any other conditions

    local cmd = string.format(...)
    if not(IS_UNIX) and cmd:sub(1, 1) == '"' then
        -- In case we're running on Windows, and if the command starts with a
        -- quote: It's reasonable (or even necessary in some cases) to enclose
        -- the entire command string in another pair of quotes. (This is needed
        -- to preserve other quotes, due to how os.execute makes use of cmd.exe)
        -- see e.g. http://lua-users.org/lists/lua-l/2014-06/msg00551.html
        cmd = '"' .. cmd .. '"'
    end

    -- print('osExec('..cmd..')')
    local exitSuccess, exitReason, exitCode = os.execute( cmd )
    -- print('\n', exitSuccess, exitReason, exitCode)

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

    -- Use heuristics to determine negative exit codes,
    -- assuming that those are in the range -8 to -1:
    if exitCode >= 248 then exitCode = exitCode - 256 end

    -- Lua 5.2+ has a weird way of dealing with exit code -1, at least on Windows
    if exitReason == 'No error' then
        exitReason = 'exit'
        exitCode = -1
    end

    if exitReason ~= 'exit' or exitCode ~= 0 then
        -- print('return false '..tostring(exitCode))
        return false, exitCode
    end

    -- print('return true')
    return true, exitCode
end

function osExpectedCodeExec( refExitCode, ... )
    local cmd = string.format(...)
    local ret, exitCode = osExec( cmd )
    if refExitCode and (exitCode ~= refExitCode) then
        error_fmt('Expected exit code %d, but got %d for: %s', refExitCode, exitCode, cmd)
    end
    return ret
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
    local idxStart, idxEnd, capture
    for line in io.lines(fileIn) do
        idxStart, idxEnd, capture = line:find( pattern )
        if idxStart ~= nil then
            if capture == nil then
                error_fmt('Must specify a capture for pattern %s in function adjustFile()', pattern)
            end
            source = capture
            break
        end
    end

    if source == nil then
        if mayBeAbsent then
            return -- no capture, just return
        end
        error_fmt('No line in file %s matching pattern "%s"', fileIn, pattern)
    end

    if verbose then
        print('Captured in source: '.. source )
    end

    local dest, linesOut = nil, {}
    for line in io.lines(fileOut) do
        idxStart, idxEnd, capture = line:find( pattern )
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
        if mayBeAbsent then
            return -- capture but nothing to adjust, just return
        end
        error_fmt('No line in file %s matching pattern "%s"', fileOut, pattern)
    end

    f = io.open( fileOut, 'w')
    f:write(table.concat(linesOut, '\n'), '\n')
    f:close()
end

function check_tap_output( fileToRun, options, output, refOutput, refExitCode )
    -- remove output
    osExpectedCodeExec(refExitCode, '%s %s --output TAP %s > %s',
                       LUA, fileToRun, options, output)

    adjustFile( output, refOutput, '# Started on (.*)')
    adjustFile( output, refOutput, '# Ran %d+ tests in (%d+.%d*).*')
    -- For Lua 5.3: stack trace uses "method" instead of "function"
    adjustFile( output, refOutput, '.*%.lua:%d+: in (%S*) .*', true, false )

    if not osExec([[diff -NPw -u -I " *\.[/\\]luaunit.lua:[0123456789]\+:.*" %s %s]], refOutput, output) then
        error('TAP Output mismatch for file : '..output)
    end
    -- report('TAP Output ok: '..output)
    return 0
end


function check_text_output( fileToRun, options, output, refOutput, refExitCode )
    -- remove output
    osExpectedCodeExec(refExitCode, '%s %s --output text %s > %s',
                       LUA, fileToRun, options, output)

    if options == '--verbose' then
        adjustFile( output, refOutput, 'Started on (.*)')
    end
    adjustFile( output, refOutput, 'Ran .* tests in (%d.%d*) seconds' )
    -- For Lua 5.3: stack trace uses "method" instead of "function"
    adjustFile( output, refOutput, '.*%.lua:%d+: in (%S*) .*', true, false )

    if not osExec([[diff -NPw -u -I " *\.[/\\]luaunit.lua:[0123456789]\+:.*" %s %s]], refOutput, output) then
        error('Text Output mismatch for file : '..output)
    end
    -- report('Text Output ok: '..output)
    return 0
end

function check_nil_output( fileToRun, options, output, refOutput, refExitCode )
    -- remove output
    osExpectedCodeExec(refExitCode, '%s %s --output nil %s > %s',
                       LUA, fileToRun, options, output)

    if not osExec([[diff -NPw -u -I " *\.[/\\]luaunit.lua:[0123456789]\+:.*" %s %s]], refOutput, output) then
        error('NIL Output mismatch for file : '..output)
    end
    -- report('NIL Output ok: '..output)
    return 0
end

function check_xml_output( fileToRun, options, output, xmlOutput, xmlLintOutput, refOutput, refXmlOutput, refExitCode )
    local retcode = 0

    -- remove output
    osExpectedCodeExec(refExitCode, '%s %s %s --output junit --name %s > %s',
                       LUA, fileToRun, options, xmlOutput, output)

    adjustFile( output, refOutput, '# XML output to (.*)')
    adjustFile( output, refOutput, '# Started on (.*)')
    adjustFile( output, refOutput, '# Ran %d+ tests in (%d+.%d*).*')
    adjustFile( xmlOutput, refXmlOutput, '.*<testsuite.*(timestamp=".-" time=".-").*')
    adjustFile( xmlOutput, refXmlOutput, '.*<testcase .*(time=".-").*' )
    -- For Lua 5.1 / 5.2 compatibility
    adjustFile( xmlOutput, refXmlOutput, '.*<property name="Lua Version" value="(Lua 5%..)"/>')
    -- For Lua 5.3: stack trace uses "method" instead of "function"
    adjustFile( output, refOutput, '.*%.lua:%d+: in (%S*) .*', true, false )
    adjustFile( xmlOutput, refXmlOutput, '.*%.lua:%d+: in (%S*) .*', true, false )


    if HAS_XMLLINT then
        -- General xmllint validation
        if osExec('xmllint --noout %s > %s', xmlOutput, xmlLintOutput) then
            -- report('XMLLint validation ok: file %s', xmlLintOutput)
        else
            error_fmt('XMLLint reported errors : file %s', xmlLintOutput)
            retcode = retcode + 1
        end

        -- Validation against apache junit schema
        if osExec('xmllint --noout --schema junitxml/junit-apache-ant.xsd %s 2> %s', xmlOutput, xmlLintOutput) then
            -- report('XMLLint validation ok: file %s', xmlLintOutput)
        else
            error_fmt('XMLLint reported errors against apache schema: file %s', xmlLintOutput)
            retcode = retcode + 1
        end

        -- Validation against jenkins/hudson schema
        if osExec('xmllint --noout --schema junitxml/junit-jenkins.xsd %s 2> %s', xmlOutput, xmlLintOutput) then
            -- report('XMLLint validation ok: file %s', xmlLintOutput)
        else
            error_fmt('XMLLint reported errors against jenkins schema: file %s', xmlLintOutput)
            retcode = retcode + 1
        end
    end

    -- ignore change in line numbers for luaunit
    if not osExec([[diff -NPw -u -I " *\.[/\\]luaunit.lua:[0123456789]\+:.*" %s %s]], refXmlOutput, xmlOutput) then
        error('XML content mismatch for file : '..xmlOutput)
        retcode = retcode + 1
    end

    if not osExec([[diff -NPw -u -I " *\.[/\\]luaunit.lua:[0123456789]\+:.*" %s %s]], refOutput, output) then
        error('XML Output mismatch for file : '..output)
        retcode = retcode + 1
    end

    --[[
    if retcode == 0 then
        report('XML Output ok: '..output)
    end
    --]]

    return retcode
end

-- test selection patterns
local EXAMPLE_PATTERN = '--pattern "Toto[^_]*$"' -- 7 tests from example_with_luaunit.lua: 1 success, 4 failures, 2 errors
local UNITTEST_PATTERN = '--pattern "[Ss]tr"' -- 23 tests from run_unit_tests.lua: all successful

-- check tap output

function testTapDefault()
    lu.assertEquals( 0,
        check_tap_output('example_with_luaunit.lua', '',          'test/exampleTapDefault.txt', 'test/ref/exampleTapDefault.txt', 12) )
    lu.assertEquals( 0,
        check_tap_output('run_unit_tests.lua', '',          'test/unitTestsTapDefault.txt', 'test/ref/unitTestsTapDefault.txt', 0 ) )
end

function testTapPattern()
    lu.assertEquals( 0,
        check_tap_output('example_with_luaunit.lua', EXAMPLE_PATTERN, 'test/exampleTapPattern.txt', 'test/ref/exampleTapPattern.txt', 6) )
    lu.assertEquals( 0,
        check_tap_output('run_unit_tests.lua', UNITTEST_PATTERN, 'test/unitTestsTapPattern.txt', 'test/ref/unitTestsTapPattern.txt', 0 ) )
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

function testTextPattern()
    lu.assertEquals( 0,
        check_text_output('example_with_luaunit.lua', EXAMPLE_PATTERN, 'test/exampleTextPattern.txt', 'test/ref/exampleTextPattern.txt', 6 ) )
    lu.assertEquals( 0,
        check_text_output('run_unit_tests.lua', UNITTEST_PATTERN, 'test/unitTestsTextPattern.txt', 'test/ref/unitTestsTextPattern.txt', 0 ) )
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

function testXmlPattern()
    lu.assertEquals( 0,
        check_xml_output('example_with_luaunit.lua', EXAMPLE_PATTERN, 'test/exampleXmlPattern.txt', 'test/exampleXmlPattern.xml',
        'test/exampleXmllintPattern.xml', 'test/ref/exampleXmlPattern.txt', 'test/ref/exampleXmlPattern.xml', 6 ) )
    lu.assertEquals( 0,
        check_xml_output('run_unit_tests.lua', UNITTEST_PATTERN, 'test/unitTestsXmlPattern.txt', 'test/unitTestsXmlPattern.xml',
        'test/unitTestsXmllintPattern.xml', 'test/ref/unitTestsXmlPattern.txt', 'test/ref/unitTestsXmlPattern.xml', 0 ) )
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
    lu.assertEquals( 0,
        check_xml_output('test/test_with_xml.lua', '', 'test/testWithXmlDefault.txt', 'test/testWithXmlDefault.xml',
        'test/testWithXmlLintDefault.txt', 'test/ref/testWithXmlDefault.txt', 'test/ref/testWithXmlDefault.xml', 2 ) )
end

function testTestXmlVerbose()
    lu.assertEquals( 0,
        check_xml_output('test/test_with_xml.lua', '--verbose', 'test/testWithXmlVerbose.txt', 'test/testWithXmlVerbose.xml',
        'test/testWithXmlLintVerbose.txt', 'test/ref/testWithXmlVerbose.txt', 'test/ref/testWithXmlVerbose.xml', 2 ) )
end

function testTestXmlQuiet()
    lu.assertEquals( 0,
        check_xml_output('test/test_with_xml.lua', '--quiet', 'test/testWithXmlQuiet.txt', 'test/testWithXmlQuiet.xml',
        'test/testWithXmlLintQuiet.txt', 'test/ref/testWithXmlQuiet.txt', 'test/ref/testWithXmlQuiet.xml', 2 ) )
end

function testLegacyLuaunitUsage()
    -- run test/legacy_example_usage and check exit status (expecting 12 failures)
    osExpectedCodeExec(12, '%s %s  --output text > %s', LUA,
        "test/legacy_example_with_luaunit.lua", "test/legacyExample.txt")
end

function testLegacyLuaunitError()
    -- run test/legacy_example_usage with "-e" option, and check exit status (-2)
    osExpectedCodeExec(-2, '%s %s  --error --output text > %s', LUA,
        "test/legacy_example_with_luaunit.lua", "test/legacyExampleError.txt")
end

function testLuaunitV2Usage()
    osExpectedCodeExec(0, '%s %s  --output text 1> %s 2>&1', LUA,
        "test/compat_luaunit_v2x.lua", "test/compat_luaunit_v2x.txt")
end

function testBasicLuaunitOptions()
    osExpectedCodeExec(0, '%s run_unit_tests.lua --help > test/null.txt', LUA)
    osExpectedCodeExec(0, '%s run_unit_tests.lua --version > test/null.txt', LUA)
    -- test invalid syntax
    osExpectedCodeExec(-1, '%s run_unit_tests.lua --foobar > test/null.txt', LUA) -- invalid option
    osExpectedCodeExec(-1, '%s run_unit_tests.lua --output foobar > test/null.txt', LUA) -- invalid format
    osExpectedCodeExec(-1, '%s run_unit_tests.lua --output junit > test/null.txt', LUA) -- missing output name
    os.remove('test/null.txt')
end

filesToGenerateExampleXml = {
    { 'example_with_luaunit.lua', '', '--output junit --name test/ref/exampleXmlDefault.xml', 'test/ref/exampleXmlDefault.txt' },
    { 'example_with_luaunit.lua', '--quiet', '--output junit --name test/ref/exampleXmlQuiet.xml', 'test/ref/exampleXmlQuiet.txt' },
    { 'example_with_luaunit.lua', '--verbose', '--output junit --name test/ref/exampleXmlVerbose.xml', 'test/ref/exampleXmlVerbose.txt' },
    { 'example_with_luaunit.lua', EXAMPLE_PATTERN, '--output junit --name test/ref/exampleXmlPattern.xml', 'test/ref/exampleXmlPattern.txt' },
}

filesToGenerateExampleTap = {
    { 'example_with_luaunit.lua', '', '--output tap', 'test/ref/exampleTapDefault.txt' },
    { 'example_with_luaunit.lua', '--quiet', '--output tap', 'test/ref/exampleTapQuiet.txt' },
    { 'example_with_luaunit.lua', '--verbose', '--output tap', 'test/ref/exampleTapVerbose.txt' },
    { 'example_with_luaunit.lua', EXAMPLE_PATTERN, '--output tap', 'test/ref/exampleTapPattern.txt' },
}

filesToGenerateExampleText = {
    { 'example_with_luaunit.lua', '', '--output text', 'test/ref/exampleTextDefault.txt' },
    { 'example_with_luaunit.lua', '--quiet', '--output text', 'test/ref/exampleTextQuiet.txt' },
    { 'example_with_luaunit.lua', '--verbose', '--output text', 'test/ref/exampleTextVerbose.txt' },
    { 'example_with_luaunit.lua', EXAMPLE_PATTERN, '--output text', 'test/ref/exampleTextPattern.txt' },
}

filesToGenerateExampleNil = {
    { 'example_with_luaunit.lua', '', '--output nil', 'test/ref/exampleNilDefault.txt' },
}

filesToGenerateUnitXml = {
    { 'run_unit_tests.lua', '', '--output junit --name test/ref/unitTestsXmlDefault.xml', 'test/ref/unitTestsXmlDefault.txt' },
    { 'run_unit_tests.lua', '--quiet', '--output junit --name test/ref/unitTestsXmlQuiet.xml', 'test/ref/unitTestsXmlQuiet.txt' },
    { 'run_unit_tests.lua', '--verbose', '--output junit --name test/ref/unitTestsXmlVerbose.xml', 'test/ref/unitTestsXmlVerbose.txt' },
    { 'run_unit_tests.lua', UNITTEST_PATTERN, '--output junit --name test/ref/unitTestsXmlPattern.xml', 'test/ref/unitTestsXmlPattern.txt' },
}

filesToGenerateUnitTap = {
    { 'run_unit_tests.lua', '', '--output tap', 'test/ref/unitTestsTapDefault.txt' },
    { 'run_unit_tests.lua', '--quiet', '--output tap', 'test/ref/unitTestsTapQuiet.txt' },
    { 'run_unit_tests.lua', '--verbose', '--output tap', 'test/ref/unitTestsTapVerbose.txt' },
    { 'run_unit_tests.lua', UNITTEST_PATTERN, '--output tap', 'test/ref/unitTestsTapPattern.txt' },
}

filesToGenerateUnitText = {
    { 'run_unit_tests.lua', '', '--output text', 'test/ref/unitTestsTextDefault.txt' },
    { 'run_unit_tests.lua', '--quiet', '--output text', 'test/ref/unitTestsTextQuiet.txt' },
    { 'run_unit_tests.lua', '--verbose', '--output text', 'test/ref/unitTestsTextVerbose.txt' },
    { 'run_unit_tests.lua', UNITTEST_PATTERN, '--output text', 'test/ref/unitTestsTextPattern.txt' },
}

filesToGenerateTestXml = {
    { 'test/test_with_xml.lua', '', '--output junit --name test/ref/testWithXmlDefault.xml', 'test/ref/testWithXmlDefault.txt' },
    { 'test/test_with_xml.lua', '--verbose', '--output junit --name test/ref/testWithXmlVerbose.xml', 'test/ref/testWithXmlVerbose.txt' },
    { 'test/test_with_xml.lua', '--quiet', '--output junit --name test/ref/testWithXmlQuiet.xml', 'test/ref/testWithXmlQuiet.txt' },
}

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
        ret = osExec( '%s %s %s %s > %s', LUA, v[1], v[2], v[3], v[4] )
        --[[
        -- exitcode != 0 is not an error for us ...
        if ret == false then
            error('Error while generating '..prettystr(v) )
            os.exit(1)
        end
        ]]
        -- neutralize all testcase time values in ref xml output
        local refXmlName = string.match(v[3], "--name (test/ref/.*%.xml)$")
        if refXmlName then
            adjustFile( refXmlName, refXmlName, '.*<testcase .*(time=".-").*' )
        end
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
            for i = 2, #arg do
                fileSet = filesSetIndex[ arg[i] ]
                if fileSet == nil then
                    local validTarget = ''
                    for k,v in pairs(filesSetIndex) do
                        validTarget = validTarget .. ' '.. k
                    end
                    error_fmt('Unable to generate files for target %s\nPossible targets: %s\n',
                              arg[i], validTarget)
                end
                -- print('Generating '..arg[i])
                updateRefFiles( fileSet )
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
