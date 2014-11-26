require('os')

function report( s )
	print('>>>>>>> '..s )
end

function validate_junit_xml()
	-- validate that junit output is a valid xml file
	-- this assumes that xmllint is installed !
	
	fnameJunitXml = 'output_junit.xml' -- os.tmpname()
	fnameJunitStdout = 'junit_stdout.txt' -- os.tmpname()
	exitSuccess, exitReason, exitCode = os.execute(string.format(
		'lua example_with_luaunit.lua --output junit --name %s > %s', fnameJunitXml, fnameJunitStdout )	 )
	exitSuccess, exitReason, exitCode = os.execute( string.format( 
		'xmllint %s', fnameJunitXml ) )
	if exitSuccess == true or (exitReason == 'exit' and exitCode == 0) then
		report(string.format('XMLLint validation successful: file %s', fnameJunitXml) )
	else
		report(string.format('XMLLint reported errors : file %s', fnameJunitXml) )
	end

end

validate_junit_xml()