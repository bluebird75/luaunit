
ChangeLog
**********


Upgrade note
================

**Important note when upgrading from version below 3.1** : there is a break of backward compatibility in version 3.1, assertions functions are no longer exported directly to the global namespace. See :ref:`luaunit-global-asserts` on how 
to adjust or restore previous behavior.


Version and Changelog
=====================

New in version 3.4 - 02 March 2021
----------------------------------
* support for Lua 5.4
* :lua:func:`assertAlmostEquals` works also on tables and nested structures
* choose test output style with environment variable `LUAUNIT_OUTPUT`
* :lua:meth:`LuaUnit.setOutputType()` accepts the xml filename as second argument when using the format *junit*
* improve printing of table information in case of cycles
* add ability to skip tests with :lua:func:`skip` and :lua:func:`skipIf`  
* detect attempts to exit the test suite before it is finished running
* add :lua:func:`assertErrorMsgContentEquals` to validate exactly any error message
* filter out some stack entries when printing assertions (useful when embedding LuaUnit inside another test layer) with :ref:`strip_extra_entries_in_stack_trace`
* add :lua:func:`assertTableContains` and :lua:func:`assertNotTableContains` to verify the presence of a given value within a table
* remove option `TABLE_EQUALS_KEYBYCONTENT`, it did not make sense
* bugfix:
    * :lua:func:`assertIs`/:lua:func:`assertNotIs` deals better with protected metatables
    * :lua:func:`assertEquals` deals better with tables containing cycles of different structure
    * fix table length comparison for table returning inconsistent length


New in version 3.3 - 6. Mar 2018
--------------------------------
* General
    * when comparing lists with :lua:func:`assertEquals`, failure message provides an advanced comparison of the lists
    * :lua:func:`assertErrorMsgEquals` can check for error raised as tables
    * tests may be finished early with :lua:func:`fail`, :lua:func:`failIf`, :lua:func:`success` or :lua:func:`successIf`
    * improve printing of recursive tables
    * improvements and fixes to JUnit and TAP output
    * stricter :lua:func:`assertTrue` and :lua:func:`assertFalse`: they only succeed with boolean values
    * add :lua:func:`assertEvalToTrue` and :lua:func:`assertEvalToFalse` with previous :lua:func:`assertTrue`/:lua:func:`assertFalse` behavior of coercing to boolean before asserting
    * all assertion functions accept an optional extra message, to be printed along the failure
* New command-line arguments:
    * can now shuffle tests with ``--shuffle`` or ``-s``
    * possibility to repeat tests (for example to trigger a JIT), with ``--repeat NUM`` or ``-r NUM``
    * more flexible test selection with inclusion (``--pattern`` / ``-p``) or exclusion (``--exclude`` / ``-x``) or combination of both
* Scientific computing dedicated support (see documentation):
    * provide the machine epsilon in EPS
    * new functions: :lua:func:`assertNan`, :lua:func:`assertInf`, :lua:func:`assertPlusInf`, :lua:func:`assertMinusInf`, :lua:func:`assertPlusZero`, :lua:func:`assertMinusZero` and
      their negative version
    * in :lua:func:`assertAlmostEquals`, margin no longer provides a default value of 1E-11, the machine epsilon is used instead
* Platform and continuous integration support:
    * validate LuaUnit on MacOs platform (thank to Travis CI)
    * validate LuaUnit with 32 bits numbers (floats) and 64 bits numbers (double)
    * add test coverage measurements thank to coveralls.io . Status: 99.76% of the code is verified.
    * use cache for AppVeyor and Travis builds
    * support for ``luarocks doc`` command
* General doc improvements (detailed description of all output, more cross-linking between sections)


New in version 3.2 - 12. Jul 2016
---------------------------------
* Add command-line option to stop on first error or failure. See :ref:`other-options`
* Distinguish between failures (failed assertion) and errors
* Support for new versions: Lua 5.3 and LuaJIT (2.0, 2.1 beta)
* Validation of all lua versions on Travis CI and AppVeyor
* Add compatibility layer with forked luaunit v2.x
* Added documentation about development process. See :ref:`developing-luaUnit`
* Improved support for table containing keys of type table. See :ref:`comparing-table-keys-table`
* Small bug fixes, several internal improvements
* Availability of a Luarock package. See `https://luarocks.org/modules/bluebird75/luaunit` .

New in version 3.1 - 10. Mar 2015
---------------------------------
* luaunit no longer pollutes global namespace, unless defining EXPORT_ASSERT_TO_GLOBALS to true. See  :ref:`luaunit-global-asserts`
* fixes and validation of JUnit XML generation
* strip luaunit internal information from stacktrace
* general improvements of test results with duration and other details
* improve printing for tables, with an option to always print table id. See :ref:`table-printing` 
* fix printing of recursive tables 

**Important note when upgrading to version 3.1** : assertions functions are
no longer exported directly to the global namespace. See :ref:`luaunit-global-asserts`

New in version 3.0 - 9. Oct 2014
--------------------------------

Because LuaUnit was forked and released as some 2.x version, version number
is now jumping to 3.0 . 

* full documentation available in text, html and pdf at http://luaunit.read-the-docs.org
* new output format: JUnit, compatible with Bamboo and other CI platforms. See :ref:`output-formats`
* much better table assertions
* new assertions for strings, with patterns and case insensitivity: assertStrContains, 
  assertNotStrContains, assertNotStrIContains, assertStrIContains, assertStrMatches
* new assertions for floats: assertAlmostEquals, assertNotAlmostEquals
* type assertions: assertIsString, assertIsNumber, ...
* error assertions: assertErrorMsgEquals, assertErrorMsgContains, assertErrorMsgMatches
* improved error messages for several assertions
* command-line options to select test, control output type and verbosity


New in version 1.5 - 8. Nov 2012
--------------------------------
* compatibility with Lua 5.1 and 5.2
* better object model internally
* a lot more of internal tests
* several internal bug fixes
* make it easy to customize the test output
* running test functions no longer requires a wrapper
* several level of verbosity


New in version 1.4 - 26. Jul 2012
---------------------------------
* switch from X11 to more popular BSD license
* add TAP output format for integration into Jenkins. See :ref:`output-formats`
* official repository now on GitHub


New in version 1.3 - 30. Oct 2007
---------------------------------
* port to lua 5.1
* iterate over the test classes, methods and functions in the alphabetical order
* change the default order of expected, actual in assertEquals.  See :ref:`equality-assertions` 


Version 1.2 - 13. Jun 2005  
---------------------------------
* first public release


Version 1.1
------------
* move global variables to internal variables
* assertion order is configurable between expected/actual or actual/expected. See :ref:`equality-assertions`
* new assertion to check that a function call returns an error
* display the calling stack when an error is spotted
* two verbosity level, like in python unittest
