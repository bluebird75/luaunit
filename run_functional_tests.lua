#!/usr/bin/env lua

require('os')
local lu = require('luaunit')


local function report( ... )
    print('>>>>>>>', string.format(...))
end

local function error_fmt( ... )
    error(string.format(...), 2) -- (level 2 = report chunk calling error_fmt)
end

local IS_UNIX = ( package.config:sub(1,1) == '/' )
local LUA='"'..arg[-1]..'"'


-- Escape a string so it can safely be used as a Lua pattern without triggering
-- special semantics. This means prepending any "magic" character ^$()%.[]*+-?
-- with a percent sign. Note: We DON'T expect embedded NUL chars, and thus
-- won't escape those (%z) for Lua 5.1.
local LUA_MAGIC_CHARS = "[%^%$%(%)%%%.%[%]%*%+%-%?]"
local function escape_lua_pattern(s)
    return s:gsub(LUA_MAGIC_CHARS, "%%%1") -- substitute with '%' + matched char
end

local function string_gsub(s, orig, repl)
    -- replace occurrence of string orig by string repl
    -- just like string.gsub, but with no pattern matching
    -- print( 'gsub_input '..s..' '..orig..' '..repl)
    return s:gsub( escape_lua_pattern(orig), repl )
end

function testStringSub()
    lu.assertEquals( string_gsub('aa a % b cc', 'a % b', 'a + b'), 'aa a + b cc' )
    lu.assertEquals( string_gsub('aa: ?cc', ': ?', 'xx?'), 'aaxx?cc' )
    lu.assertEquals( string_gsub('aa b: cc b: ee', 'b:', 'xx'), 'aa xx cc xx ee' )
end

local function osExec( ... )
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

    if exitReason == nil and exitCode == nil then
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

local function osExpectedCodeExec( refExitCode, ... )
    local cmd = string.format(...)
    local ret, exitCode = osExec( cmd )
    if refExitCode and (exitCode ~= refExitCode) then
        error_fmt('Expected exit code %d, but got %d for: %s', refExitCode, exitCode, cmd)
    end
    return ret
end

local HAS_XMLLINT 
do
    local xmllint_output_fname = 'test/has_xmllint.txt'
    HAS_XMLLINT = osExec('xmllint --version 2> '..xmllint_output_fname)
    if not HAS_XMLLINT then
        report('WARNING: xmllint absent, can not validate xml validity')
    end
    os.remove(xmllint_output_fname)
end

local function adjustFile( fileOut, fileIn, pattern, mayBeAbsent, verbose )
    --[[ Adjust the content of fileOut by copying lines matching pattern from fileIn

    fileIn lines are read and the first line matching pattern is analysed. The first pattern
    capture is memorized.

    fileOut lines are then read, and the first line matching pattern is modified, by applying
    the first capture of fileIn. fileOut is then rewritten.

    In most cases, pattern2 may be nil in which case, pattern is used when matching in fileout.
    ]]
    if verbose then
        print('Using reference file: '..fileIn)
    end
    local source, idxStart, idxEnd, capture = nil
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
        print('Modifying file: '..fileOut)
    end

    local dest, linesOut = nil, {}
    for line in io.lines(fileOut) do
        idxStart, idxEnd, capture = line:find( pattern )
        while idxStart ~= nil do
            if capture == nil then
                print('missing pattern for outfile!')
            end
            dest = capture
            if verbose then
                print('Modifying line: '..line )
            end
            line = string_gsub(line, dest, source)
            -- line = line:sub(1,idxStart-1)..source..line:sub(idxEnd+1)
            -- string.gsub( line, dest, source )
            if verbose then
                print('Result        : '..line )
            end
            idxStart, idxEnd, capture = line:find( pattern, idxEnd )
        end
        table.insert( linesOut, line )
    end

    if dest == nil then
        if mayBeAbsent then
            return -- capture but nothing to adjust, just return
        end
        error_fmt('No line in file %s matching pattern "%s"', fileOut, pattern)
    end

    local f = io.open( fileOut, 'w')
    f:write(table.concat(linesOut, '\n'), '\n')
    f:close()
end

local function check_tap_output( fileToRun, options, output, refOutput, refExitCode, envOptions, outputArg )
    -- remove output
    envOptions = envOptions or ''
    outputArg = outputArg or ''

    -- by default, if nothing is provided, we set output explicitely
    -- but we leave the option for the caller to provide either environment and/or output arguments
    if envOptions == '' and outputArg == '' then
        outputArg = '--output TAP'
    end

    if envOptions ~= '' then
        envOptions = '/usr/bin/env ' .. envOptions
    end

    osExpectedCodeExec(refExitCode, '%s %s %s %s %s > %s',
                       envOptions, LUA, fileToRun, outputArg, options, output)

    adjustFile( output, refOutput, '# Started on (.*)')
    adjustFile( output, refOutput, '# Ran %d+ tests in (%d+.%d*).*')
    if _VERSION ~= 'Lua 5.2' and _VERSION ~= 'Lua 5.1' then
        -- For Lua 5.3: stack trace uses "method" instead of "function"
        adjustFile( output, refOutput, '.*%.lua:%d+: in (%S*) .*', true )
    end

    if not osExec([[diff -NPw -u -I " *\.[/\\]luaunit.lua:[0123456789]\+:.*" %s %s]], refOutput, output) then
        error('TAP Output mismatch for file : '..output)
    end
    -- report('TAP Output ok: '..output)
    return 0
end


local function check_text_output( fileToRun, options, output, refOutput, refExitCode )
    -- remove output
    osExpectedCodeExec(refExitCode, '%s %s --output text %s > %s',
                       LUA, fileToRun, options, output)

    if options:find( '--verbose' ) then
        adjustFile( output, refOutput, 'Started on (.*)')
    end
    adjustFile( output, refOutput, 'Ran .* tests in (%d.%d*) seconds' )
    adjustFile( output, refOutput, 'Ran .* tests in (%d.%d*) seconds' )
    adjustFile( output, refOutput, 'thread: (0?x?[%x]+)', true )
    adjustFile( output, refOutput, 'function: (0?x?[%x]+)', true )
    adjustFile( output, refOutput, '<table (01%-0?x?[%x]+)>', true )
    adjustFile( output, refOutput, '<table (02%-0?x?[%x]+)>', true )
    if _VERSION ~= 'Lua 5.2' and _VERSION ~= 'Lua 5.1' then
        -- For Lua 5.3: stack trace uses "method" instead of "function"
        adjustFile( output, refOutput, '.*%.lua:%d+: in (%S*) .*', true )
    end

    if not osExec([[diff -NPw -u -I " *\.[/\\]luaunit.lua:[0123456789]\+:.*" %s %s]], refOutput, output) then
        error('Text Output mismatch for file : '..output)
    end
    -- report('Text Output ok: '..output)
    return 0
end

local function check_nil_output( fileToRun, options, output, refOutput, refExitCode )
    -- remove output
    osExpectedCodeExec(refExitCode, '%s %s --output nil %s > %s',
                       LUA, fileToRun, options, output)

    if not osExec([[diff -NPw -u -I " *\.[/\\]luaunit.lua:[0123456789]\+:.*" %s %s]], refOutput, output) then
        error('NIL Output mismatch for file : '..output)
    end
    -- report('NIL Output ok: '..output)
    return 0
end

local function check_xml_output( fileToRun, options, output, xmlOutput, xmlLintOutput, refOutput, refXmlOutput, refExitCode, envOptions, outputArg )
    local retcode = 0

    envOptions = envOptions or ''
    outputArg = outputArg or ''

    -- by default, if nothing is provided, we set output explicitely
    -- but we leave the option for the caller to provide either environment and/or output arguments
    if envOptions == '' and outputArg == '' then
        outputArg = '--output junit --name '..xmlOutput
    end

    if envOptions ~= '' then
        envOptions = '/usr/bin/env ' .. envOptions
    end

    -- remove output
    osExpectedCodeExec(refExitCode, '%s %s %s %s %s > %s',
                       envOptions, LUA, fileToRun, outputArg, options, output)

    adjustFile( output, refOutput, '# XML output to (.*)')
    adjustFile( output, refOutput, '# Started on (.*)')
    adjustFile( output, refOutput, '# Ran %d+ tests in (%d+.%d*).*')
    adjustFile( xmlOutput, refXmlOutput, '.*<testsuite.*(timestamp=".-" time=".-").*')
    adjustFile( xmlOutput, refXmlOutput, '.*<testcase .*(time=".-").*' )
    -- For Lua 5.1 / 5.2 compatibility
    adjustFile( xmlOutput, refXmlOutput, '.*<property name="Lua Version" value="(Lua 5%..)"/>')

    if _VERSION ~= 'Lua 5.2' and _VERSION ~= 'Lua 5.1' then
        -- For Lua 5.3: stack trace uses "method" instead of "function"
        -- For Lua 5.4: stack trace uses "method" or "upvalue" instead of "function"
        adjustFile( output, refOutput, '.*%.lua:%d+: in (%S*) .*', true )
        adjustFile( xmlOutput, refXmlOutput, '.*%.lua:%d+: in (%S*) .*', true )
    end

    if HAS_XMLLINT then
        -- General xmllint validation
        if osExec('xmllint --noout %s > %s', xmlOutput, xmlLintOutput) then
            -- report('XMLLint validation ok: file %s', xmlLintOutput)
        else
            error_fmt('XMLLint reported errors : file %s', xmlLintOutput)
            retcode = retcode + 1
        end

        -- we used to validate against apache and/maven xsd but the way it handles skipped test
        -- is just too specific. I prefer the jenkins way.

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

-- check tap output

function testTapDefault()
    lu.assertEquals( 0,
        check_tap_output('example_with_luaunit.lua', '',
            'test/exampleTapDefault.txt', 
            'test/ref/exampleTapDefault.txt', 12) )
    lu.assertEquals( 0,
        check_tap_output('test/test_with_err_fail_pass.lua', '',
            'test/errFailPassTapDefault.txt', 
            'test/ref/errFailPassTapDefault.txt', 10 ) )
    lu.assertEquals( 0,
        check_tap_output('test/test_with_err_fail_pass.lua', '-p Succ',
            'test/errFailPassTapDefault-success.txt', 
            'test/ref/errFailPassTapDefault-success.txt', 0 ) )
    lu.assertEquals( 0,
        check_tap_output('test/test_with_err_fail_pass.lua', '-p Succ -p Fail',
            'test/errFailPassTapDefault-failures.txt', 
            'test/ref/errFailPassTapDefault-failures.txt', 5 ) )
    if IS_UNIX then
        -- It is non-trivial to set the environment for new command execution
        -- on Windows, so we'll only attempt it on UNIX.  These systems should
        -- all have /usr/bin/env
        lu.assertEquals( 0,
            check_tap_output('test/test_with_err_fail_pass.lua', '-p Succ -p Fail',
                'test/errFailPassTapDefault-failures.txt', 
                'test/ref/errFailPassTapDefault-failures.txt', 5,
                'LUAUNIT_OUTPUT=TAP' ) )

        -- force an alternate file format, check that command-line option prevails
        lu.assertEquals( 0,
            check_tap_output('test/test_with_err_fail_pass.lua', '-p Succ -p Fail',
                'test/errFailPassTapDefault-failures.txt', 
                'test/ref/errFailPassTapDefault-failures.txt', 5,
                'LUAUNIT_OUTPUT=TEXT', '--output tap' ) )
    end
end

function testTapVerbose()
    lu.assertEquals( 0,
        check_tap_output('example_with_luaunit.lua', '--verbose', 
            'test/exampleTapVerbose.txt', 
            'test/ref/exampleTapVerbose.txt', 12 ) )
    lu.assertEquals( 0,
        check_tap_output('test/test_with_err_fail_pass.lua', '--verbose',
            'test/errFailPassTapVerbose.txt', 
            'test/ref/errFailPassTapVerbose.txt', 10 ) )
    lu.assertEquals( 0,
        check_tap_output('test/test_with_err_fail_pass.lua', '--verbose -p Succ',
            'test/errFailPassTapVerbose-success.txt', 
            'test/ref/errFailPassTapVerbose-success.txt', 0 ) )
    lu.assertEquals( 0,
        check_tap_output('test/test_with_err_fail_pass.lua', '--verbose -p Succ -p Fail',
            'test/errFailPassTapVerbose-failures.txt', 
            'test/ref/errFailPassTapVerbose-failures.txt', 5 ) )
end

function testTapQuiet()
    lu.assertEquals( 0,
        check_tap_output('example_with_luaunit.lua', '--quiet',   'test/exampleTapQuiet.txt',   'test/ref/exampleTapQuiet.txt', 12 ) )
    lu.assertEquals( 0,
        check_tap_output('test/test_with_err_fail_pass.lua', '--quiet',
            'test/errFailPassTapQuiet.txt', 
            'test/ref/errFailPassTapQuiet.txt', 10 ) )
    lu.assertEquals( 0,
        check_tap_output('test/test_with_err_fail_pass.lua', '--quiet -p Succ',
            'test/errFailPassTapQuiet-success.txt', 
            'test/ref/errFailPassTapQuiet-success.txt', 0 ) )
    lu.assertEquals( 0,
        check_tap_output('test/test_with_err_fail_pass.lua', '--quiet -p Succ -p Fail',
            'test/errFailPassTapQuiet-failures.txt', 
            'test/ref/errFailPassTapQuiet-failures.txt', 5 ) )
end

-- check text output

function testTextDefault()
    lu.assertEquals( 0,
        check_text_output('example_with_luaunit.lua', '',
            'test/exampleTextDefault.txt', 
            'test/ref/exampleTextDefault.txt', 12 ) )
    lu.assertEquals( 0,
        check_text_output('test/test_with_err_fail_pass.lua', '',
            'test/errFailPassTextDefault.txt', 
            'test/ref/errFailPassTextDefault.txt', 10 ) )
    lu.assertEquals( 0,
        check_text_output('test/test_with_err_fail_pass.lua', '-p Succ',
            'test/errFailPassTextDefault-success.txt', 
            'test/ref/errFailPassTextDefault-success.txt', 0 ) )
    lu.assertEquals( 0,
        check_text_output('test/test_with_err_fail_pass.lua', '-p Succ -p Fail',
            'test/errFailPassTextDefault-failures.txt', 
            'test/ref/errFailPassTextDefault-failures.txt', 5 ) )
end

function testTextVerbose()
    lu.assertEquals( 0,
        check_text_output('example_with_luaunit.lua', '--verbose', 'test/exampleTextVerbose.txt', 'test/ref/exampleTextVerbose.txt', 12 ) )
    lu.assertEquals( 0,
        check_text_output('test/test_with_err_fail_pass.lua', '--verbose',
            'test/errFailPassTextVerbose.txt', 
            'test/ref/errFailPassTextVerbose.txt', 10 ) )
    lu.assertEquals( 0,
        check_text_output('test/test_with_err_fail_pass.lua', '--verbose -p Succ',
            'test/errFailPassTextVerbose-success.txt', 
            'test/ref/errFailPassTextVerbose-success.txt', 0 ) )
    lu.assertEquals( 0,
        check_text_output('test/test_with_err_fail_pass.lua', '--verbose -p Succ -p Fail',
            'test/errFailPassTextVerbose-failures.txt', 
            'test/ref/errFailPassTextVerbose-failures.txt', 5 ) )
end

function testTextQuiet()
    lu.assertEquals( 0,
        check_text_output('example_with_luaunit.lua', '--quiet',   
            'test/exampleTextQuiet.txt',   
            'test/ref/exampleTextQuiet.txt', 12 ) )
    lu.assertEquals( 0,
        check_text_output('test/test_with_err_fail_pass.lua', '--quiet',
            'test/errFailPassTextQuiet.txt', 
            'test/ref/errFailPassTextQuiet.txt', 10 ) )
    lu.assertEquals( 0,
        check_text_output('test/test_with_err_fail_pass.lua', '--quiet -p Succ',
            'test/errFailPassTextQuiet-success.txt', 
            'test/ref/errFailPassTextQuiet-success.txt', 0 ) )
    lu.assertEquals( 0,
        check_text_output('test/test_with_err_fail_pass.lua', '--quiet -p Succ -p Fail',
            'test/errFailPassTextQuiet-failures.txt', 
            'test/ref/errFailPassTextQuiet-failures.txt', 5 ) )
end

-- check nil output

function testNilDefault()
    lu.assertEquals( 0,
        check_nil_output('example_with_luaunit.lua', '', 'test/exampleNilDefault.txt', 'test/ref/exampleNilDefault.txt', 12 ) )
    lu.assertEquals( 0,
        check_nil_output('test/test_with_err_fail_pass.lua', '',
            'test/errFailPassNilDefault.txt', 
            'test/ref/errFailPassNilDefault.txt', 10 ) )
    lu.assertEquals( 0,
        check_nil_output('test/test_with_err_fail_pass.lua', ' -p Succ',
            'test/errFailPassNilDefault-success.txt', 
            'test/ref/errFailPassNilDefault-success.txt', 0 ) )
    lu.assertEquals( 0,
        check_nil_output('test/test_with_err_fail_pass.lua', ' -p Succ -p Fail',
            'test/errFailPassNilDefault-failures.txt', 
            'test/ref/errFailPassNilDefault-failures.txt', 5 ) )
end

-- check xml output

function testXmlDefault()
    lu.assertEquals( 0,
        check_xml_output('example_with_luaunit.lua', '',
            'test/exampleXmlDefault.txt', 'test/exampleXmlDefault.xml', 'test/exampleXmllintDefault.xml', 
            'test/ref/exampleXmlDefault.txt', 'test/ref/exampleXmlDefault.xml', 12 ) )
    lu.assertEquals( 0,
        check_xml_output('test/test_with_err_fail_pass.lua', '',
            'test/errFailPassXmlDefault.txt', 'test/errFailPassXmlDefault.xml', 'test/errFailPassXmllintDefault.xml',
            'test/ref/errFailPassXmlDefault.txt', 'test/ref/errFailPassXmlDefault.xml', 10 ) )
    lu.assertEquals( 0,
        check_xml_output('test/test_with_err_fail_pass.lua', '-p Succ',
            'test/errFailPassXmlDefault-success.txt', 'test/errFailPassXmlDefault-success.xml', 'test/errFailPassXmllintDefault.xml',
            'test/ref/errFailPassXmlDefault-success.txt', 'test/ref/errFailPassXmlDefault-success.xml', 0 ) )
    lu.assertEquals( 0,
        check_xml_output('test/test_with_err_fail_pass.lua', '-p Succ -p Fail',
            'test/errFailPassXmlDefault-failures.txt', 'test/errFailPassXmlDefault-failures.xml', 'test/errFailPassXmllintDefault.xml',
            'test/ref/errFailPassXmlDefault-failures.txt', 'test/ref/errFailPassXmlDefault-failures.xml', 5 ) )

    -- disable this test not working !
    if IS_UNIX and false then
        -- It is non-trivial to set the environment for new command execution
        -- on Windows, so we'll only attempt it on UNIX.  These systems should
        -- all have /usr/bin/env
        lu.assertEquals( 0,
            check_xml_output('test/test_with_err_fail_pass.lua', '-p Succ -p Fail',
                'test/errFailPassXmlDefault-failures.txt', 'test/errFailPassXmlDefault-failures.xml', 'test/errFailPassXmllintDefault.xml',
                'test/ref/errFailPassXmlDefault-failures.txt', 'test/ref/errFailPassXmlDefault-failures.xml', 5,
                'LUAUNIT_OUTPUT=JUNIT LUAUNIT_JUNIT_FNAME=test/ref/errFailPassXmlDefault-failures.xml', '' ) )
    end

end

function testXmlVerbose()
    lu.assertEquals( 0,
        check_xml_output('example_with_luaunit.lua', '--verbose', 
            'test/exampleXmlVerbose.txt', 'test/exampleXmlVerbose.xml', 'test/exampleXmllintVerbose.xml', 
            'test/ref/exampleXmlVerbose.txt', 'test/ref/exampleXmlVerbose.xml', 12 ) )
    lu.assertEquals( 0,
        check_xml_output('test/test_with_err_fail_pass.lua', '--verbose ',
            'test/errFailPassXmlVerbose.txt', 'test/errFailPassXmlVerbose.xml', 'test/errFailPassXmllintVerbose.xml',
            'test/ref/errFailPassXmlVerbose.txt', 'test/ref/errFailPassXmlVerbose.xml', 10 ) )
    lu.assertEquals( 0,
        check_xml_output('test/test_with_err_fail_pass.lua', '--verbose -p Succ',
            'test/errFailPassXmlVerbose-success.txt', 'test/errFailPassXmlVerbose-success.xml', 'test/errFailPassXmllintVerbose.xml',
            'test/ref/errFailPassXmlVerbose-success.txt', 'test/ref/errFailPassXmlVerbose-success.xml', 0 ) )
    lu.assertEquals( 0,
        check_xml_output('test/test_with_err_fail_pass.lua', '--verbose -p Succ -p Fail',
            'test/errFailPassXmlVerbose-failures.txt', 'test/errFailPassXmlVerbose-failures.xml', 'test/errFailPassXmllintVerbose.xml',
            'test/ref/errFailPassXmlVerbose-failures.txt', 'test/ref/errFailPassXmlVerbose-failures.xml', 5 ) )
end

function testXmlQuiet()
    lu.assertEquals( 0,
        check_xml_output('example_with_luaunit.lua', '--quiet',   'test/exampleXmlQuiet.txt', 'test/exampleXmlQuiet.xml',
        'test/exampleXmllintQuiet.xml', 'test/ref/exampleXmlQuiet.txt', 'test/ref/exampleXmlQuiet.xml', 12 ) )
    lu.assertEquals( 0,
        check_xml_output('test/test_with_err_fail_pass.lua', '--quiet ',
            'test/errFailPassXmlQuiet.txt', 'test/errFailPassXmlQuiet.xml', 'test/errFailPassXmllintQuiet.xml',
            'test/ref/errFailPassXmlQuiet.txt', 'test/ref/errFailPassXmlQuiet.xml', 10 ) )
    lu.assertEquals( 0,
        check_xml_output('test/test_with_err_fail_pass.lua', '--quiet -p Succ',
            'test/errFailPassXmlQuiet-success.txt', 'test/errFailPassXmlQuiet-success.xml', 'test/errFailPassXmllintQuiet.xml',
            'test/ref/errFailPassXmlQuiet-success.txt', 'test/ref/errFailPassXmlQuiet-success.xml', 0 ) )
    lu.assertEquals( 0,
        check_xml_output('test/test_with_err_fail_pass.lua', '--quiet -p Succ -p Fail',
            'test/errFailPassXmlQuiet-failures.txt', 'test/errFailPassXmlQuiet-failures.xml', 'test/errFailPassXmllintQuiet.xml',
            'test/ref/errFailPassXmlQuiet-failures.txt', 'test/ref/errFailPassXmlQuiet-failures.xml', 5 ) )
end

function testTestWithXmlDefault()
    lu.assertEquals( 0,
        check_xml_output('test/test_with_xml.lua', '', 'test/testWithXmlDefault.txt', 'test/testWithXmlDefault.xml',
        'test/testWithXmlLintDefault.txt', 'test/ref/testWithXmlDefault.txt', 'test/ref/testWithXmlDefault.xml', 2 ) )
end

function testTestWithXmlVerbose()
    lu.assertEquals( 0,
        check_xml_output('test/test_with_xml.lua', '--verbose', 'test/testWithXmlVerbose.txt', 'test/testWithXmlVerbose.xml',
        'test/testWithXmlLintVerbose.txt', 'test/ref/testWithXmlVerbose.txt', 'test/ref/testWithXmlVerbose.xml', 2 ) )
end

function testTestWithXmlQuiet()
    lu.assertEquals( 0,
        check_xml_output('test/test_with_xml.lua', '--quiet', 'test/testWithXmlQuiet.txt', 'test/testWithXmlQuiet.xml',
        'test/testWithXmlLintQuiet.txt', 'test/ref/testWithXmlQuiet.txt', 'test/ref/testWithXmlQuiet.xml', 2 ) )
end

function testListComparison()
    -- run test/some_lists_comparisons and check exit status 
    lu.assertEquals( 0,
        check_text_output('test/some_lists_comparisons.lua', '--verbose',
            'test/some_lists_comparisons.txt', 
            'test/ref/some_lists_comparisons.txt', 11 ) )
end

function testLegacyLuaunitUsage()
    -- run test/legacy_example_usage and check exit status (expecting 12 failures)
    osExpectedCodeExec(12, '%s %s  --output text > %s', LUA,
        "test/legacy_example_with_luaunit.lua", "test/legacyExample.txt")
end

function testLuaunitV2Usage()
    osExpectedCodeExec(0, '%s %s  --output text 1> %s 2>&1', LUA,
        "test/compat_luaunit_v2x.lua", "test/compat_luaunit_v2x.txt")
end

function testBasicLuaunitOptions()
    osExpectedCodeExec(0, '%s example_with_luaunit.lua --help > test/null.txt', LUA)
    osExpectedCodeExec(0, '%s example_with_luaunit.lua --version > test/null.txt', LUA)
    -- test invalid syntax
    osExpectedCodeExec(-1, '%s example_with_luaunit.lua --foobar > test/null.txt', LUA) -- invalid option
    osExpectedCodeExec(-1, '%s example_with_luaunit.lua --output foobar > test/null.txt', LUA) -- invalid format
    osExpectedCodeExec(-1, '%s example_with_luaunit.lua --output junit > test/null.txt', LUA) -- missing output name
    os.remove('test/null.txt')
end

function testStopOnError()
    lu.assertEquals( 0,
        check_text_output('test/test_with_err_fail_pass.lua', '--quiet -p Succ --error --failure',
            'test/errFailPassTextStopOnError-1.txt', 
            'test/ref/errFailPassTextStopOnError-1.txt', 0 ) )
    lu.assertEquals( 0,
        check_text_output('test/test_with_err_fail_pass.lua', '--quiet -p TestSome --error',
            'test/errFailPassTextStopOnError-2.txt', 
            'test/ref/errFailPassTextStopOnError-2.txt', -2 ) )
    lu.assertEquals( 0,
        check_text_output('test/test_with_err_fail_pass.lua', '--quiet -p TestAnoth --failure',
            'test/errFailPassTextStopOnError-3.txt', 
            'test/ref/errFailPassTextStopOnError-3.txt', -2 ) )
    lu.assertEquals( 0,
        check_text_output('test/test_with_err_fail_pass.lua', '--quiet -p TestSome --failure',
            'test/errFailPassTextStopOnError-4.txt', 
            'test/ref/errFailPassTextStopOnError-4.txt', -2 ) )
end

local filesToGenerateExampleXml = {
    { 'example_with_luaunit.lua', '', '--output junit --name test/ref/exampleXmlDefault.xml', 'test/ref/exampleXmlDefault.txt' },
    { 'example_with_luaunit.lua', '--quiet', '--output junit --name test/ref/exampleXmlQuiet.xml', 'test/ref/exampleXmlQuiet.txt' },
    { 'example_with_luaunit.lua', '--verbose', '--output junit --name test/ref/exampleXmlVerbose.xml', 'test/ref/exampleXmlVerbose.txt' },
}

local filesToGenerateExampleTap = {
    { 'example_with_luaunit.lua', '', '--output tap', 'test/ref/exampleTapDefault.txt' },
    { 'example_with_luaunit.lua', '--quiet', '--output tap', 'test/ref/exampleTapQuiet.txt' },
    { 'example_with_luaunit.lua', '--verbose', '--output tap', 'test/ref/exampleTapVerbose.txt' },
}

local filesToGenerateExampleText = {
    { 'example_with_luaunit.lua', '', '--output text', 'test/ref/exampleTextDefault.txt' },
    { 'example_with_luaunit.lua', '--quiet', '--output text', 'test/ref/exampleTextQuiet.txt' },
    { 'example_with_luaunit.lua', '--verbose', '--output text', 'test/ref/exampleTextVerbose.txt' },
}

local filesToGenerateExampleNil = {
    { 'example_with_luaunit.lua', '', '--output nil', 'test/ref/exampleNilDefault.txt' },
}

local filesToGenerateErrFailPassXml = {
    { 'test/test_with_err_fail_pass.lua', '', 
        '--output junit --name test/ref/errFailPassXmlDefault.xml', 
        'test/ref/errFailPassXmlDefault.txt' },
    { 'test/test_with_err_fail_pass.lua', '', 
        '-p Succ --output junit --name test/ref/errFailPassXmlDefault-success.xml', 
        'test/ref/errFailPassXmlDefault-success.txt' },
    { 'test/test_with_err_fail_pass.lua', '', 
        '-p Succ -p Fail --output junit --name test/ref/errFailPassXmlDefault-failures.xml', 
        'test/ref/errFailPassXmlDefault-failures.txt' },
    { 'test/test_with_err_fail_pass.lua', '', '--quiet --output junit --name test/ref/errFailPassXmlQuiet.xml',
        'test/ref/errFailPassXmlQuiet.txt' },
    { 'test/test_with_err_fail_pass.lua', '', 
        '-p Succ --quiet --output junit --name test/ref/errFailPassXmlQuiet-success.xml', 
        'test/ref/errFailPassXmlQuiet-success.txt' },
    { 'test/test_with_err_fail_pass.lua', '', 
        '-p Succ -p Fail --quiet --output junit --name test/ref/errFailPassXmlQuiet-failures.xml', 
        'test/ref/errFailPassXmlQuiet-failures.txt' },
    { 'test/test_with_err_fail_pass.lua', '', '--verbose --output junit --name test/ref/errFailPassXmlVerbose.xml', 'test/ref/errFailPassXmlVerbose.txt' },
    { 'test/test_with_err_fail_pass.lua', '', 
        '-p Succ --verbose --output junit --name test/ref/errFailPassXmlVerbose-success.xml', 
        'test/ref/errFailPassXmlVerbose-success.txt' },
    { 'test/test_with_err_fail_pass.lua', '', 
        '-p Succ -p Fail --verbose --output junit --name test/ref/errFailPassXmlVerbose-failures.xml', 
        'test/ref/errFailPassXmlVerbose-failures.txt' },
}

local filesToGenerateErrFailPassTap = {
    { 'test/test_with_err_fail_pass.lua', '', '--output tap', 'test/ref/errFailPassTapDefault.txt' },
    { 'test/test_with_err_fail_pass.lua', '-p Succ', '--output tap', 'test/ref/errFailPassTapDefault-success.txt' },
    { 'test/test_with_err_fail_pass.lua', '-p Succ -p Fail', '--output tap', 'test/ref/errFailPassTapDefault-failures.txt' },

    { 'test/test_with_err_fail_pass.lua', '--quiet', '--output tap', 'test/ref/errFailPassTapQuiet.txt' },
    { 'test/test_with_err_fail_pass.lua', '-p Succ --quiet', 
        '--output tap', 'test/ref/errFailPassTapQuiet-success.txt' },
    { 'test/test_with_err_fail_pass.lua', '-p Succ -p Fail --quiet', 
        '--output tap', 'test/ref/errFailPassTapQuiet-failures.txt' },

    { 'test/test_with_err_fail_pass.lua', '--verbose', '--output tap', 'test/ref/errFailPassTapVerbose.txt' },
    { 'test/test_with_err_fail_pass.lua', '-p Succ --verbose', 
        '--output tap', 'test/ref/errFailPassTapVerbose-success.txt' },
    { 'test/test_with_err_fail_pass.lua', '-p Succ -p Fail --verbose', 
        '--output tap', 'test/ref/errFailPassTapVerbose-failures.txt' },
}

local filesToGenerateErrFailPassText = {
    { 'test/test_with_err_fail_pass.lua', '', '--output text', 'test/ref/errFailPassTextDefault.txt' },
    { 'test/test_with_err_fail_pass.lua', '-p Succ', '--output text', 'test/ref/errFailPassTextDefault-success.txt' },
    { 'test/test_with_err_fail_pass.lua', '-p Succ -p Fail', '--output text', 'test/ref/errFailPassTextDefault-failures.txt' },
    { 'test/test_with_err_fail_pass.lua', '--quiet', '--output text', 'test/ref/errFailPassTextQuiet.txt' },
    { 'test/test_with_err_fail_pass.lua', '-p Succ --quiet', 
        '--output text', 'test/ref/errFailPassTextQuiet-success.txt' },
    { 'test/test_with_err_fail_pass.lua', '-p Succ -p Fail --quiet', 
        '--output text', 'test/ref/errFailPassTextQuiet-failures.txt' },
    { 'test/test_with_err_fail_pass.lua', '--verbose', '--output text', 'test/ref/errFailPassTextVerbose.txt' },
    { 'test/test_with_err_fail_pass.lua', '-p Succ --verbose', 
        '--output text', 'test/ref/errFailPassTextVerbose-success.txt' },
    { 'test/test_with_err_fail_pass.lua', '-p Succ -p Fail --verbose', 
        '--output text', 'test/ref/errFailPassTextVerbose-failures.txt' },
}

local filesToGenerateTestXml = {
    { 'test/test_with_xml.lua', '', '--output junit --name test/ref/testWithXmlDefault.xml', 'test/ref/testWithXmlDefault.txt' },
    { 'test/test_with_xml.lua', '--verbose', '--output junit --name test/ref/testWithXmlVerbose.xml', 'test/ref/testWithXmlVerbose.txt' },
    { 'test/test_with_xml.lua', '--quiet', '--output junit --name test/ref/testWithXmlQuiet.xml', 'test/ref/testWithXmlQuiet.txt' },
}

local filesToGenerateStopOnError = {
    { 'test/test_with_err_fail_pass.lua', '', '--output text --quiet -p Succ --error --failure',
        'test/ref/errFailPassTextStopOnError-1.txt'},
    { 'test/test_with_err_fail_pass.lua', '', '--output text --quiet -p TestSome --error',
        'test/ref/errFailPassTextStopOnError-2.txt'},
    { 'test/test_with_err_fail_pass.lua', '', '--output text --quiet -p TestAnoth --failure',
        'test/ref/errFailPassTextStopOnError-3.txt'},
    { 'test/test_with_err_fail_pass.lua', '', '--output text --quiet -p TestSome --failure',
        'test/ref/errFailPassTextStopOnError-4.txt'},
}

local filesToGenerateListsComp = {
    { 'test/some_lists_comparisons.lua', '', '--output text --verbose',
        'test/ref/some_lists_comparisons.txt'},
}

local function table_join(...)
    local args = {...}
    local ret = {}
    for i,t in ipairs(args) do
        for _,v in ipairs(t) do 
            table.insert( ret, v)
        end
    end
    return ret
end

local filesSetIndex = {
    ErrFailPassText=filesToGenerateErrFailPassText,
    ErrFailPassTap=filesToGenerateErrFailPassTap,
    ErrFailPassXml=filesToGenerateErrFailPassXml,
    ErrFail = table_join( filesToGenerateErrFailPassText, 
                          filesToGenerateErrFailPassTap, 
                          filesToGenerateErrFailPassXml ),
    ExampleNil=filesToGenerateExampleNil,
    ExampleText=filesToGenerateExampleText,
    ExampleTap=filesToGenerateExampleTap,
    ExampleXml=filesToGenerateExampleXml,
    Example = table_join(   filesToGenerateExampleNil,
                            filesToGenerateExampleText,
                            filesToGenerateExampleTap,
                            filesToGenerateExampleXml ),
    TestXml=filesToGenerateTestXml,
    StopOnError=filesToGenerateStopOnError,
    ListsComp=filesToGenerateListsComp,
}

local function updateRefFiles( filesToGenerate )
    local ret

    for _,v in ipairs(filesToGenerate) do 
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


local function main()
    if arg[1] == '--coverage' then
        LUA = LUA .." -lluacov" -- run tests with LuaCov active
        table.remove(arg, 1)
    end

    if arg[1] ~= '--with-linting' then
        HAS_XMLLINT = false
    else
        table.remove(arg, 1)
    end
    
    if arg[1] == '--update' then
        if #arg == 1 then
            -- generate all files
            -- print('Generating all files' )
            for _,v in pairs(filesSetIndex) do 
                -- print('Generating '..v )
                updateRefFiles( v )
            end
        else
            -- generate subset of files
            for i = 2, #arg do
                local fileSet = filesSetIndex[ arg[i] ]
                if fileSet == nil then
                    local validTarget = ''
                    for k,_ in pairs(filesSetIndex) do
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
