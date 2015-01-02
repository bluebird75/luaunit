require('os')
require('luaunit')

function report( s )
    print('>>>>>>> '..s )
end

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

function osExec( s )
    -- execute s with os.execute and return true if exit code is 0
    -- false in any other conditions

    -- print('osExec('..s..')')
    local exitSuccess, exitReason, exitCode 
    exitSuccess, exitReason, exitCode = os.execute( s )
    -- print(exitSuccess)
    -- print(exitReason)
    -- print(exitCode)

    -- Lua 5.1 : exitSuccess == 0
    -- Lua 5.2 : exitSuccess == true and exitReason == exit and exitCode == 0
    if exitSuccess == 0 or (exitSuccess == true and exitReason == 'exit' and exitCode == 0) then
        return true
    else
        return false
    end
end

function adjustFile( fileOut, fileIn, pattern )
    --[[ Adjust the content of fileOut by copying lines matching pattern from fileIn

    fileIn lines are read and the first line matching pattern is analysed. The first pattern
    capture is memorized.

    fileOut lines are then read, and the first line matching pattern is modified, by applying
    the first capture of fileIn. fileOut is then rewritten.
    ]]
    local source = nil
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
        error('No line in file '..fileIn..' matching pattern "'..pattern..'"')
    end

    -- print('Captured in source: '.. source )

    local dest = nil
    local linesOut = {}
    for line in io.lines(fileOut) do
        local idxStart, idxEnd, capture = string.find( line, pattern )
        if idxStart ~= nil then
            dest = capture
            -- print('Modifying line: '..line )
            line = string.gsub(line, dest, source)
            -- line = line:sub(1,idxStart-1)..source..line:sub(idxEnd+1)
            -- string.gsub( line, dest, source )
            -- print('Result: '..line )
        end
        table.insert( linesOut, line )
    end

    if dest == nil then
        error('No line in file '..fileOut..' matching pattern '..pattern )
    end

    f = io.open( fileOut, 'w')
    for i,l in ipairs(linesOut) do
        f:write( l..'\n' )
    end
    f:close()

end

function check_tap_output( fileToRun, options, output, refOutput )
    local ret
    -- remove output
    ret = osExec(string.format(
            'lua %s  --output TAP %s > %s', fileToRun, options, output )  )
    adjustFile( output, refOutput, '# Started on (.*)')
    adjustFile( output, refOutput, '# Ran %d+ tests in (%d+.%d*).*')
    if options == '--verbose' then
        -- For Lua 5.1 / 5.2 compatibility
        adjustFile( output, refOutput, '(%s+%[C%]: i?n? ?%?)' )
    end

    ret = osExec( string.format('diff -NP -u %s %s', refOutput, output ) )
    if not ret then
        error('TAP Output mismatch for file : '..output)
    end
    -- report('TAP Output ok: '..output)
    return 0
end


function check_text_output( fileToRun, options, output, refOutput )
    local ret
    -- remove output
    ret = osExec(string.format(
            'lua %s  --output text %s > %s', fileToRun, options, output )  )
    if options ~= '--quiet' then
        adjustFile( output, refOutput, 'Started on (.*)')
    end
    adjustFile( output, refOutput, 'Success: .*, executed in (%d.%d*) seconds' )
 

    ret = osExec( string.format('diff -NP -u %s %s', refOutput, output ) )
    if not ret then
        error('Text Output mismatch for file : '..output)
        return 1
    end
    -- report('Text Output ok: '..output)
    return 0
end

function check_nil_output( fileToRun, options, output, refOutput )
    local ret
    -- remove output
    ret = osExec(string.format(
            'lua %s  --output nil %s > %s', fileToRun, options, output )  )

    ret = osExec( string.format('diff -NP -u %s %s', refOutput, output ) )
    if not ret then
        error('NIL Output mismatch for file : '..output)
    end
    -- report('NIL Output ok: '..output)
    return 0
end

function check_xml_output( fileToRun, options, output, xmlOutput, xmlLintOutput, refOutput, refXmlOutput )
    local ret, retcode
    retcode = 0

    -- remove output
    ret = osExec(string.format(
            'lua %s %s --output junit --name %s > %s', fileToRun, options, xmlOutput, output )  )

    adjustFile( output, refOutput, '# XML output to (.*)')
    adjustFile( output, refOutput, '# Started on (.*)')
    adjustFile( output, refOutput, '# Ran %d+ tests in (%d+.%d*).*')
    -- For Lua 5.1 / 5.2 compatibility
    adjustFile( output, refOutput, '(.+%[C%]: i?n? ?%?)' )
    adjustFile( xmlOutput, refXmlOutput, '(.+%[C%]: i?n? ?%?.*)' )

    ret = osExec( string.format('xmllint %s > %s', xmlOutput, xmlLintOutput ) )
    if ret then
        -- report(string.format('XMLLint validation ok: file %s', xmlLintOutput) )
    else
        error(string.format('XMLLint reported errors : file %s', xmlLintOutput) )
        retcode = retcode + 1
    end

    ret = osExec( string.format('diff -NP -u %s %s', refXmlOutput, xmlOutput ) )
    if not ret then
        error('XML content mismatch for file : '..xmlOutput)
        retcode = retcode + 1
    end

    ret = osExec( string.format('diff -NP -u %s %s', refOutput, output ) )
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

function testExampleTapDefault()
    assertEquals( 0,
        check_tap_output('example_with_luaunit.lua', '',          'test/exampleTapDefault.txt', 'test/ref/exampleTapDefault.txt' ) )
end

function testExampleTapVerbose( ... )
    assertEquals( 0,
        check_tap_output('example_with_luaunit.lua', '--verbose', 'test/exampleTapVerbose.txt', 'test/ref/exampleTapVerbose.txt' ) )
end

function testExampleTapQuiet( ... )
    assertEquals( 0,
        check_tap_output('example_with_luaunit.lua', '--quiet',   'test/exampleTapQuiet.txt',   'test/ref/exampleTapQuiet.txt' ) )
end

-- check text output

function testExampleTextDefault()
    assertEquals( 0,
        check_text_output('example_with_luaunit.lua', '',          'test/exampleTextDefault.txt', 'test/ref/exampleTextDefault.txt' ) )
end

function testExampleTextVerbose( ... )
    assertEquals( 0,
        check_text_output('example_with_luaunit.lua', '--verbose', 'test/exampleTextVerbose.txt', 'test/ref/exampleTextVerbose.txt' ) )
end

function testExampleTextQuiet( ... )
    assertEquals( 0,
        check_text_output('example_with_luaunit.lua', '--quiet',   'test/exampleTextQuiet.txt',   'test/ref/exampleTextQuiet.txt' ) )
end

-- check nil output

function testExampleNilDefault()
    assertEquals( 0,
        check_nil_output('example_with_luaunit.lua', '', 'test/exampleNilDefault.txt', 'test/ref/exampleNilDefault.txt' ) )
end

-- check xml output

function testExampleXmlDefault()
    assertEquals( 0,
        check_xml_output('example_with_luaunit.lua', '',          'test/exampleXmlDefault.txt', 'test/exampleXmlDefault.xml',
        'test/exampleXmllintDefault.xml', 'test/ref/exampleXmlDefault.txt', 'test/ref/exampleXmlDefault.xml' ) )
end

function testExampleXmlVerbose()
    assertEquals( 0,
        check_xml_output('example_with_luaunit.lua', '--verbose', 'test/exampleXmlVerbose.txt', 'test/exampleXmlVerbose.xml',
        'test/exampleXmllintVerbose.xml', 'test/ref/exampleXmlVerbose.txt', 'test/ref/exampleXmlVerbose.xml' ) )
end

function testExampleXmlQuiet()
    assertEquals( 0,
        check_xml_output('example_with_luaunit.lua', '--quiet',   'test/exampleXmlQuiet.txt', 'test/exampleXmlQuiet.xml',
        'test/exampleXmllintQuiet.xml', 'test/ref/exampleXmlQuiet.txt', 'test/ref/exampleXmlQuiet.xml' ) )
end

function testTestXmlDefault()
    assertEquals( 0,
        check_xml_output('test/test_with_xml.lua', '', 'test/testWithXmlDefault.txt', 'test/testWithXmlDefault.xml',
        'test/testWithXmlLintDefault.txt', 'test/ref/testWithXmlDefault.txt', 'test/ref/testWithXmlDefault.xml' ) )
end



os.exit( LuaUnit.run() )

-- TODO check output of run_unit_tests
-- TODO check return values of execution


