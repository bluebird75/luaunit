[![Build status](https://ci.appveyor.com/api/projects/status/us6uh4e5q597jj54?svg=true&passingText=Windows%20Build%20passing&failingText=Windows%20Build%20failed)](https://ci.appveyor.com/project/bluebird75/luaunit)
[![Build Status](https://travis-ci.org/bluebird75/luaunit.svg?branch=master)](https://travis-ci.org/bluebird75/luaunit)
[![Documentation Status](https://readthedocs.org/projects/luaunit/badge/?version=latest)](https://readthedocs.org/projects/luaunit/?badge=latest)
[![Coverage Status](https://coveralls.io/repos/github/bluebird75/luaunit/badge.svg?branch=master)](https://coveralls.io/github/bluebird75/luaunit?branch=master)
[![Downloads](https://img.shields.io/badge/downloads-235k-brightgreen.svg)](https://luarocks.org/modules/bluebird75/luaunit)
[![License](http://img.shields.io/badge/License-BSD-green.svg)](LICENSE.txt)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/2756/badge)](https://bestpractices.coreinfrastructure.org/projects/2756)

## LuaUnit
by Philippe Fremy

LuaUnit is a popular unit-testing framework for Lua, with an interface typical
of xUnit libraries (Python unittest, Junit, NUnit, ...). It supports 
several output formats (Text, TAP, JUnit, ...) to be used directly or work with Continuous Integration platforms
(Jenkins, Hudson, ...).

LuaUnit may be installed as a [rock](https://luarocks.org/modules/bluebird75/luaunit) or directly added to your project.
For simplicity, LuaUnit is contained into a single-file and has no external dependency. 

Tutorial and reference documentation is available on
[read-the-docs](http://luaunit.readthedocs.org/en/latest/)

LuaUnit may also be used as an assertion library, to validate assertions inside a running program. In addition, it provides
a pretty stringifier which converts any type into a nicely formatted string (including complex nested or recursive tables).

## More details

LuaUnit provides a wide range of assertions and goes into great efforts to provide the most useful output. For example
since version 3.3 , comparing lists will provide a detailed difference analysis:

	-- lua test code. Can you spot the difference ?
    function TestListCompare:test1()
        local A = { 121221, 122211, 121221, 122211, 121221, 122212, 121212, 122112, 122121, 121212, 122121 } 
        local B = { 121221, 122211, 121221, 122211, 121221, 122212, 121212, 122112, 121221, 121212, 122121 }
        lu.assertEquals( A, B )
    end

    $ lua test_some_lists_comparison.lua

    TestListCompare.test1 ... FAIL
	test/some_lists_comparisons.lua:22: expected: 

	List difference analysis:
	* lists A (actual) and B (expected) have the same size
	* lists A and B start differing at index 9
	* lists A and B are equal again from index 10
	* Common parts:
	  = A[1], B[1]: 121221
	  = A[2], B[2]: 122211
	  = A[3], B[3]: 121221
	  = A[4], B[4]: 122211
	  = A[5], B[5]: 121221
	  = A[6], B[6]: 122212
	  = A[7], B[7]: 121212
	  = A[8], B[8]: 122112
	* Differing parts:
	  - A[9]: 122121
	  + B[9]: 121221
	* Common parts at the end of the lists
	  = A[10], B[10]: 121212
	  = A[11], B[11]: 122121


The command-line options provide a flexible interface to select tests by name or patterns, control output
format, set verbosity and more. See [the documentation](http://luaunit.readthedocs.io/en/latest/#command-line-options) .

LuaUnit also provides some dedicated support to scientific computing. See [the documentation](http://luaunit.readthedocs.io/en/latest/#scientific-computing-and-luaunit) .

LuaUnit is very well tested: code coverage is 99.5% . The test suite is run on every version of Lua (Lua 5.1 to 5.4, LuaJIT 2.0 and 2.1 beta)
and on many OS (Windows Seven, Windows Server 2012, MacOs X and Ubuntu). You can check the continuous build results on [Travis-CI](https://travis-ci.org/bluebird75/luaunit) and [AppVeyor](https://ci.appveyor.com/project/bluebird75/luaunit).

LuaUnit is maintained on GitHub: https://github.com/bluebird75/luaunit . We gladly accept feature requests and even better Pull Requests.
For more information on LuaUnit development, please check: [Developing LuaUnit](http://luaunit.readthedocs.org/en/latest/#developing-luaunit) . 

LuaUnit is released under the BSD license.

The main developer can be reached at *phil.fremy at free.fr* . If you have security issue to report requiring confidentiality, this is the address to use.

## LuaUnit successes

Version 3.2 of LuaUnit has been downloaded more than 235 000 times on [LuaRocks](https://luarocks.org/modules/bluebird75/luaunit)

LuaUnit is used in some very nice technological products. I like to mention:

* [SchedMD/Slurm](https://www.schedmd.com/): Slurm is an open-source cluster resource management and job scheduling 
system that strives to be simple, scalable, portable, fault-tolerant, and interconnect agnostic. On the June 2017 Top 500 computer 
list, Slurm was performing workload management on six of the ten most powerful computers in the world including the number 1 system, 
Sunway TaihuLight with 10,649,600 computing cores. LuaUnit is used by Slurm to validate plugins written in Lua. Thanks Douglas Jacobsen
to contribute back to LuaUnit. See the [GitHub repository of Slurm](https://github.com/SchedMD/slurm) .

* [MAD by the CERN](http://mad.web.cern.ch/mad/): CERN is the European Organization for Nuclear Research, where physicists and engineers are 
probing the fundamental structure of the universe. MAD is one of the CERN project: MAD aims to be at the forefront of computational physics in 
the field of particle accelerator design and simulation. Its scripting language is de facto the standard to describe particle accelerators, simulate 
beam dynamics and optimize beam optics at CERN. Lua is the main language of MAD-ng, the new generatino of MAD. A fork of LuaUnit is used extensively 
for all MAD calculation and framework validation. Thanks Laurent Deniau for contributing back to LuaUnit. See the [GitHub repository of MAD](https://github.com/MethodicalAcceleratorDesign/MAD) .

## Contributors
* [NiteHawk](https://github.com/n1tehawk)
* [AbigailBuccaneer](https://github.com/AbigailBuccaneer)
* [Juan Julián Merelo Guervós](https://github.com/JJ)
* [Naoyuki Totani](https://github.com/ntotani)
* [Jennal](https://github.com/Jennal)
* [George Zhao](https://github.com/zhaozg)
* kbuschelman
* [Victor Seva](https://github.com/linuxmaniac)
* [Urs Breu](https://github.com/ubreu)
* Jim Anderson
* [Douglas Jacobsen](https://github.com/dmjacobsen)
* [Mayama Takeshi](https://github.com/MayamaTakeshi)


## Installation

**LuaRocks**

LuaUnit is available on [LuaRocks](https://luarocks.org/modules/bluebird75/luaunit). To install it, you need at least 
LuaRocks version 2.4.4 (due to old versions of wget being incompatible with GitHub https downloading)

**GitHub** 

The simplest way to install LuaUnit is to fetch the GitHub version:

    git clone git@github.com:bluebird75/luaunit.git

Then copy the file luaunit.lua into your project or the Lua libs directory.

The version of the main branch on GitHub is always stable and can be used safely.

### History 

#### Version 3.4 - 02 March 2021
* support for Lua 5.4
* assertAlmostEquals() works also on tables and nested structures
* choose test output style with environment variable LUAUNIT_OUTPUT
* setOutputType() accepts the xml filename as second argument when using the format junit
* improve printing of table information in case of cycles
* add ability to skip tests with XXX
* detect attempts to exit the test suite before it is finished running
* add assertErrorMsgContentEquals() to validate exactly any error message
* filter out some stack entries when printing assertions (useful when embedding LuaUnit inside another test layer) with XXX
* add assertTableContains() and assertNotTableContains() to verify the presence of a given value within a table XXX
* remove option TABLE_EQUALS_KEYBYCONTENT, it did not make sense
* bugfix:
	* assertIs()/assertNotIs() deals better with protected metatables
	* assertEquals() deals better with tables containing cycles of different structure
	* fix table length comparison for table returning inconsistent length


#### Version 3.3 - 6. March 2018
* General
    * when comparing lists with assertEquals(), failure message provides an advanced comparison of the lists
    * assertErrorMsgEquals() can check for error raised as tables
    * tests may be finished early with fail(), failIf(), success() or successIf()
    * improve printing of recursive tables
    * improvements and fixes to JUnit and TAP output
    * stricter assertTrue() and assertFalse(): they only succeed with boolean values
    * add assertEvalToTrue() and assertEvalToFalse() with previous assertTrue()/assertFalse() behavior of coercing to boolean before asserting
        ** all assertion functions accept an optional extra message, to be printed along the failure
* New command-line arguments:
	* can now shuffle tests with --shuffle or -s
	* possibility to repeat tests (for example to trigger a JIT), with --repeat NUM or -r NUM
	* more flexible test selection with inclusion (--pattern / -p) or exclusion (--exclude / -x) or combination of both
* Scientific computing dedicated support (see documentation):
	* provide the machine epsilon in lu.EPS
	* new functions: assertNan(), assertInf(), assertPlusInf(), assertMinusInf(), assertPlusZero(), assertMinusZero()
	* in assertAlmostEquals( a, b, margin ), margin no longer provides a default value of 1E-11, the machine epsilon is used instead
* Platform and continuous integration support:
	* validate LuaUnit on MacOs platform (thank to Travis CI)
	* validate LuaUnit with 32 bits numbers (floats) and 64 bits numbers (double)
	* add test coverage measurements thank to coveralls.io . Status: 99.76% of the code is verified.
	* use cache for AppVeyor and Travis builds
	* support for luarocks doc command
* General doc improvements (detailed description of all output, more cross-linking between sections)


#### Version 3.2 - 12. Jul 2016
* distinguish between failures (failed assertion) and errors
* add command-line option to stop on first error or failure
* support for new versions: Lua 5.3 and LuaJIT (2.0, 2.1 beta)
* validation of all lua versions on Travis CI and AppVeyor
* added compatibility layer with forked luaunit v2.x
* added documentation about development process
* improved support for table containing keys of type table
* small bug fixes, several internal improvements


#### Version 3.1 - 10 Mar. 2015
* luaunit no longer pollutes global namespace, unless defining EXPORT_ASSERT_TO_GLOBALS to true
* fixes and validation of JUnit XML generation
* strip luaunit internal information from stacktrace
* general improvements of test results with duration and other details
* improve printing for tables, with an option to always print table id
* fix printing of recursive tables 

**Important note when upgrading to version 3.1** : assertions functions are
no longer exported directly to the global namespace. See documentation for upgrade
paths.


#### Version 3.0 - 9. Oct 2014

Since some people have forked LuaUnit and release some 2.x version, I am
jumping the version number to 3.

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


#### Version 2.0
Unofficial fork from version 1.3 by rjbcomupting
- lua 5.2 module style, without global namespace pollution
- setUp() may be named Setup() or setup()
- tearDown() may be named Teardown() or teardown()
- wrapFunction() may be called WrapFunctions() or wrap_functions()
- run() may also be called Run()
- table deep comparision (also available in 1.4)
- control verbosity with setVerbosity() SetVerbosity() and set_verbosity()
- More assertions: 
  - is<Type>, is_<type>, assert<Type> and assert_<type> (e.g. assert( LuaUnit.isString( getString() ) )
  - assertNot<Type> and assert_not_<type>


#### Version 1.5 - 8. Nov 2012
- compatibility with Lua 5.1 and 5.2
- better object model internally
- a lot more of internal tests
- several internal bug fixes
- make it easy to customize the test output
- running test functions no longer requires a wrapper
- several level of verbosity


#### Version 1.4 - 26. Jul 2012
- table deep comparison
- switch from X11 to more popular BSD license
- add TAP output format for integration into Jenkins
- official repository now on GitHub


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

![stats](https://stats.sylphide-consulting.com/piwik/piwik.php?idsite=37&rec=1)

