require('os')

function report( s )
	print('>>>>>>> '..s )
end

function validate_junit_xml( generateJunitXml )
	-- Set generateJunitXml to refresh XML. Default is true.

	local retCode = 0
	-- validate that junit output is a valid xml file
	-- this assumes that xmllint is installed !

	if generateJunitXml == nil then
		generateJunitXml = true
	end

	fnameJunitXml = 'test/output_junit.xml' -- os.tmpname()
	fnameJunitStdout = 'test/junit_stdout.txt' -- os.tmpname()
	if generateJunitXml then
		exitSuccess, exitReason, exitCode = os.execute(string.format(
			'lua example_with_luaunit.lua --output junit --name %s > %s', fnameJunitXml, fnameJunitStdout )	 )
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


-- main section
errorCount = 0
errorCount = errorCount + validate_junit_xml()
os.exit( errorCount )

