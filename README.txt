		LuaUnit  by Philippe Fremy

Luaunit is a unit-testing framework for Lua. It allows you 
to write test functions and test classes with test methods, combined with 
setup/teardown functionality. A wide range of assertions are supported.

Luaunit supports several output format, like Junit or TAP, for easier integration
into Continuous Integration platforms (Jenkins, Maven, ...) . The integrated command-line 
options provide a flexible interface to select tests by name or patterns, control output 
format, set verbosity, ...

LuaUnit works with Lua 5.1 and 5.2 . It was tested on Windows XP and Ubuntu 12.04 (see 
continuous build results on travic-ci.org ) and should work on all platforms supported by lua.
It has no other dependency than lua itself. 

Luaunit is now maintained on github:
https://github.com/bluebird75/luaunit

It is released under the BSD license.

See file example_with_luaunit.lua to understand how to use it.

History:
========


version 1.6:
------------
- moved to Github
- full documentation available in text and html
- new output format: JUnit
- much better table assertions
- new assertions for strings, with patterns and case insensitivity: assertStrContains, 
  assertNotStrContains, assertNotStrIContains, assertStrIContains
- new assertions for floats: assertAlmostEquals, assertNotAlmostEquals
- type assertions: assertIsString, assertIsNumber, ...
- improved error messages for several assertions
- command-line options to select test, control output type and verbosity


version 1.5: 8. Nov 2012
------------
- compatibility with Lua 5.1 and 5.2
- better object model internally
- a lot more of internal tests
- several internal bug fixes
- make it easy to customize the test output
- running test functions no longer requires a wrapper
- several level of verbosity


version 1.4: 26. Jul 2012
------------
- switch from X11 to more popular BSD license
- add TAP output format for integration into Jenkins
- official repository now on github


version 1.3: 30. Oct 2007
------------
- port to lua 5.1
- iterate over the test classes, methods and functions in the alphabetical order
- change the default order of expected, actual in assertEquals (adjustable with USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS).


version 1.2: 13. Jun 2005  
------------
- first public release


version 1.1:
------------
- move global variables to internal variables
- assertion order is configurable between expected/actual or actual/expected
- new assertion to check that a function call returns an error
- display the calling stack when an error is spotted
- two verbosity level, like in python unittest

