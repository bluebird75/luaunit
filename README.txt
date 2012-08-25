		luaunit.lua  by Philippe Fremy

Luaunit is a unit-testing framework for Lua, in the spirit of many
others unit-testing framework. Luaunit let's you write test functions,
test classes with test methods and setup/teardown functionality.

Luaunit can output test failures using the TAP format, for easier integration
into Continuous Integration platforms like Jenkins.

Luaunit is derived from the initial work of Ryu Gwang. 
It is released under the BSD license.

Luaunit should work on all platforms supported by lua. It was tested on
Windows XP and Gentoo Linux.

Luaunit is now maintained on github:
https://github.com/bluebird75/luaunit

See file example_with_luaunit.lua to understand how to use it.

History:
========

version 1.5: (in progress)
------------
- compatibility with Lua 5.1 and 5.2
- better object model internally
- a lot more of internal tests
- several internal bug fixes
- make it easy to customize the test output


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

