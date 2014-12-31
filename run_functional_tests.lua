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

function check_junit_xml( fileToRun, fnameJunitXml, fnameJunitStdout, generateJunitXml )
    -- Set generateJunitXml to refresh XML. Default is true.
    local retCode = 0
    local ret
    -- check that junit output is a valid xml file
    -- this assumes that xmllint is installed !

    if generateJunitXml == nil then
        generateJunitXml = true
    end

    if generateJunitXml then
        ret = osExec(string.format(
            'lua %s  --output junit --name %s > %s', fileToRun, fnameJunitXml, fnameJunitStdout )  )
    end
    ret = osExec( string.format('xmllint %s', fnameJunitXml ) )

    if ret then
        report(string.format('XMLLint validation ok: file %s', fnameJunitXml) )
    else
        report(string.format('XMLLint reported errors : file %s', fnameJunitXml) )
        retCode = 1
    end
    return retCode
end

function check_tap_output( fileToRun, options, output, refOutput )
    local ret
    -- remove output
    ret = osExec(string.format(
            'lua %s  --output TAP %s > %s', fileToRun, options, output )  )
    adjustFile( output, refOutput, '# Started on (.*)')
    adjustFile( output, refOutput, '# Ran %d+ tests in (%d+.%d*).*')

    ret = osExec( string.format(
        -- ignore the first line that include the date, always different
        -- ignore the last line that include the dureation, always different
        -- NOTE: we need to find a better way to compare the last line
        'diff -NP -u %s %s', refOutput, output ) )
    if not ret then
        report('TAP Ouptut mismatch for file : '..output)
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
 

    ret = osExec( string.format(
        -- ignore the first line that include the date, always different
        -- ignore the last line that include the dureation, always different
        -- NOTE: we need to find a better way to compare the last line
        'diff -NP -u %s %s', refOutput, output ) )
    if not ret then
        report('Ouptut mismatch for file : '..output)
        return 1
    end
    report('Output ok: '..output)
    return 0
end

function main( )
    fnameJunitXml = 'test/output_junit.xml' -- os.tmpname()
    fnameJunitStdout = 'test/junit_stdout.txt' -- os.tmpname()

    errorCount = 0

    function check( result )
        errorCount = errorCount + result
    end

    -- check xml conformity
    check( check_junit_xml('example_with_luaunit.lua', 'test/output_junit.xml',  'test/junit_stdout.txt' ) )
    check( check_junit_xml('test/test_with_xml.lua',   'test/output_junit2.xml', 'test/junit_stdout2.txt' ) )

    -- check tap output
    check( check_tap_output('example_with_luaunit.lua', '',          'test/exampleTapDefault.txt', 'test/ref/exampleTapDefault.txt' ) )
    check( check_tap_output('example_with_luaunit.lua', '--verbose', 'test/exampleTapVerbose.txt', 'test/ref/exampleTapVerbose.txt' ) )
    check( check_tap_output('example_with_luaunit.lua', '--quiet',   'test/exampleTapQuiet.txt',   'test/ref/exampleTapQuiet.txt' ) )

    -- check text output
    check( check_text_output('example_with_luaunit.lua', '',          'test/exampleTextDefault.txt', 'test/ref/exampleTextDefault.txt' ) )
    check( check_text_output('example_with_luaunit.lua', '--verbose', 'test/exampleTextVerbose.txt', 'test/ref/exampleTextVerbose.txt' ) )
    check( check_text_output('example_with_luaunit.lua', '--quiet',   'test/exampleTextQuiet.txt',   'test/ref/exampleTextQuiet.txt' ) )

    os.exit( errorCount )
end

main()

