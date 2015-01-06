## LuaUnit  
	by Philippe Fremy

[![Build status](https://ci.appveyor.com/api/projects/status/us6uh4e5q597jj54?svg=true&passingText=Windows%20Build%20passing&failingText=Windows%20Build%20failed)](https://ci.appveyor.com/project/bluebird75/luaunit)
[![Build Status](https://travis-ci.org/bluebird75/luaunit.svg?branch=master)](https://travis-ci.org/bluebird75/luaunit)
[![Documentation Status](https://readthedocs.org/projects/luaunit/badge/?version=latest)](https://readthedocs.org/projects/luaunit/?badge=latest)

Luaunit is a unit-testing framework for Lua. It allows you 
to write test functions and test classes with test methods, combined with 
setup/teardown functionality. A wide range of assertions are supported.

Luaunit supports several output format, like Junit or TAP, for easier integration
into Continuous Integration platforms (Jenkins, Maven, ...) . The integrated command-line 
options provide a flexible interface to select tests by name or patterns, control output 
format, set verbosity, ...

LuaUnit works with Lua 5.1 and 5.2 . It was tested on Windows XP, Windows Server 2012 R2 (x64) and Ubuntu 14.04 (see 
continuous build results on [Travis-CI](https://travis-ci.org/bluebird75/luaunit) and [AppVeyor](https://ci.appveyor.com/project/bluebird75/luaunit) ) and should work on all platforms supported by lua.
It has no other dependency than lua itself. 

LuaUnit is packed into a single-file. To make start using it, just add the file to your project.

LuaUnit is maintained on github:
https://github.com/bluebird75/luaunit

It is released under the BSD license.

Documentation is available on [read-the-docs](http://luaunit.readthedocs.org/en/latest/)

**Community**

LuaUnit has a mailing list with low activity (a few emails per months). To subscribe or read the archives, please go to: [LuaUnit Mailing-list](http://lists.freehackers.org/list/luaunit%40freehackers.org/). If you are using LuaUnit, please drop us a note, we are always happy to hear from new users.

### History 

#### Version 3.0 - 9. Oct 2014

Since some people have forked LuaUnit and release some 2.x version, I am
jumping the version number.

- moved to Github
- full documentation available in text, html and pdf at read-the-docs.org
- new output format: JUnit
- much better table assertions
- new assertions for strings, with patterns and case insensitivity: assertStrContains, 
  assertNotStrContains, assertNotStrIContains, assertStrIContains, assertStrMatches
- new assertions for floats: assertAlmostEquals, assertNotAlmostEquals
- type assertions: assertIsString, assertIsNumber, ...
- error assertions: assertErrorMsgEquals, assertErrorMsgContains, assertErrorMsgMatches
- improved error messages for several assertions
- command-line options to select test, control output type and verbosity


#### Version 1.5 - 8. Nov 2012
- compatibility with Lua 5.1 and 5.2
- better object model internally
- a lot more of internal tests
- several internal bug fixes
- make it easy to customize the test output
- running test functions no longer requires a wrapper
- several level of verbosity


#### Version 1.4 - 26. Jul 2012
- switch from X11 to more popular BSD license
- add TAP output format for integration into Jenkins
- official repository now on github


#### Version 1.3 - 30. Oct 2007
- port to lua 5.1
- iterate over the test classes, methods and functions in the alphabetical order
- change the default order of expected, actual in assertEquals (adjustable with USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS).


#### Version 1.2 - 13. Jun 2005  
- first public release


#### Version 1.1
- move global variables to internal variables
- assertion order is configurable between expected/actual or actual/expected
- new assertion to check that a function call returns an error
- display the calling stack when an error is spotted
- two verbosity level, like in python unittest

