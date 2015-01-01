require('os')

function report( s )
    print('>>>>>>> '..s )
end

function osExec( s )
    -- execute s with os.execute and return true if exit code is 0
    -- false in any other conditions

    -- print('osExec('..s..')')
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
    source = nil
    for line in io.lines(fileIn) do
        idxStart, idxEnd, capture = string.find( line, pattern )
        if idxStart ~= nil then
            source = capture
            break
        end
    end

    if source == nil then
        error('No line in file '..fileIn..' matching pattern "'..pattern..'"')
    end

    -- print('Captured: '.. source )

    dest = nil
    linesOut = {}
    for line in io.lines(fileOut) do
        idxStart, idxEnd, capture = string.find( line, pattern )
        if idxStart ~= nil then
            dest = capture
            -- print('Modifying line: '..line )
            line = string.gsub( line, dest, source )
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

    ret = osExec( string.format('diff -NP -u %s %s', refOutput, output ) )
    if not ret then
        report('TAP Output mismatch for file : '..output)
        return 1
    end
    report('TAP Output ok: '..output)
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
        report('Text Output mismatch for file : '..output)
        return 1
    end
    report('Text Output ok: '..output)
    return 0
end

function check_nil_output( fileToRun, options, output, refOutput )
    local ret
    -- remove output
    ret = osExec(string.format(
            'lua %s  --output nil %s > %s', fileToRun, options, output )  )

    ret = osExec( string.format('diff -NP -u %s %s', refOutput, output ) )
    if not ret then
        report('NIL Output mismatch for file : '..output)
        return 1
    end
    report('NIL Output ok: '..output)
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

    ret = osExec( string.format('xmllint %s > %s', xmlOutput, xmlLintOutput ) )
    if ret then
        report(string.format('XMLLint validation ok: file %s', xmlLintOutput) )
    else
        report(string.format('XMLLint reported errors : file %s', xmlLintOutput) )
        retcode = retcode + 1
    end

    ret = osExec( string.format('diff -NP -u %s %s', refXmlOutput, xmlOutput ) )
    if not ret then
        report('XML content mismatch for file : '..xmlOutput)
        retcode = retcode + 1
    end

    ret = osExec( string.format('diff -NP -u %s %s', refOutput, output ) )
    if not ret then
        report('XML Output mismatch for file : '..output)
        retcode = retcode + 1
    end

    if retcode == 0 then
        report('XML Output ok: '..output)
    end

    return retcode
end

function main( )
    fnameJunitXml = 'test/output_junit.xml' -- os.tmpname()
    fnameJunitStdout = 'test/junit_stdout.txt' -- os.tmpname()

    errorCount = 0

    function check( result )
        errorCount = errorCount + result
    end

    -- check tap output
    check( check_tap_output('example_with_luaunit.lua', '',          'test/exampleTapDefault.txt', 'test/ref/exampleTapDefault.txt' ) )
    check( check_tap_output('example_with_luaunit.lua', '--verbose', 'test/exampleTapVerbose.txt', 'test/ref/exampleTapVerbose.txt' ) )
    check( check_tap_output('example_with_luaunit.lua', '--quiet',   'test/exampleTapQuiet.txt',   'test/ref/exampleTapQuiet.txt' ) )

    -- check text output
    check( check_text_output('example_with_luaunit.lua', '',          'test/exampleTextDefault.txt', 'test/ref/exampleTextDefault.txt' ) )
    check( check_text_output('example_with_luaunit.lua', '--verbose', 'test/exampleTextVerbose.txt', 'test/ref/exampleTextVerbose.txt' ) )
    check( check_text_output('example_with_luaunit.lua', '--quiet',   'test/exampleTextQuiet.txt',   'test/ref/exampleTextQuiet.txt' ) )

    -- check nil output
    check( check_nil_output('example_with_luaunit.lua', '', 'test/exampleNilDefault.txt', 'test/ref/exampleNilDefault.txt' ) )

    -- check xml output
    check( check_xml_output('example_with_luaunit.lua', '',          'test/exampleXmlDefault.txt', 'test/exampleXmlDefault.xml',
        'test/exampleXmllintDefault.xml', 'test/ref/exampleXmlDefault.txt', 'test/ref/exampleXmlDefault.xml' ) )
    check( check_xml_output('example_with_luaunit.lua', '--verbose', 'test/exampleXmlVerbose.txt', 'test/exampleXmlVerbose.xml',
        'test/exampleXmllintVerbose.xml', 'test/ref/exampleXmlVerbose.txt', 'test/ref/exampleXmlVerbose.xml' ) )
    check( check_xml_output('example_with_luaunit.lua', '--quiet',   'test/exampleXmlQuiet.txt', 'test/exampleXmlQuiet.xml',
        'test/exampleXmllintQuiet.xml', 'test/ref/exampleXmlQuiet.txt', 'test/ref/exampleXmlQuiet.xml' ) )

    os.exit( errorCount )
end

main()

