require('os')

function report( s )
    print('>>>>>>> '..s )
end

function validate_junit_xml( fileToRun, fnameJunitXml, fnameJunitStdout, generateJunitXml )
    -- Set generateJunitXml to refresh XML. Default is true.

    local retCode = 0
    -- validate that junit output is a valid xml file
    -- this assumes that xmllint is installed !

    if generateJunitXml == nil then
        generateJunitXml = true
    end

    if generateJunitXml then
        exitSuccess, exitReason, exitCode = os.execute(string.format(
            'lua %s  --output junit --name %s > %s', fileToRun, fnameJunitXml, fnameJunitStdout )  )
    end
    exitSuccess, exitReason, exitCode = os.execute( string.format( 
        'xmllint %s', fnameJunitXml ) )

    -- Lua 5.1 : exitSuccess == 0
    -- Lua 5.2 : exitSuccess == true and exitReason == exit and exitCode == 0
    if exitSuccess == 0 or (exitSuccess == true and exitReason == 'exit' and exitCode == 0) then
        report(string.format('XMLLint validation successful: file %s', fnameJunitXml) )
    else
        report(string.format('XMLLint reported errors : file %s', fnameJunitXml) )
        retCode = 1
    end
    return retCode
end

function main( )
    fnameJunitXml = 'test/output_junit.xml' -- os.tmpname()
    fnameJunitStdout = 'test/junit_stdout.txt' -- os.tmpname()

    errorCount = 0
    errorCount = errorCount + validate_junit_xml( 
        'example_with_luaunit.lua',
        'test/output_junit.xml', 
        'test/junit_stdout.txt' 
    )
    errorCount = errorCount + validate_junit_xml( 
        'test/test_with_xml.lua',
        'test/output_junit2.xml', 
        'test/junit_stdout2.txt' 
    )
    os.exit( errorCount )
end

-- main()

