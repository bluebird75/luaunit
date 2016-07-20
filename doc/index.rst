.. LuaUnit documentation master file, created by
   sphinx-quickstart on Thu Aug 21 21:45:55 2014.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.


,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
Welcome to LuaUnit's documentation!
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

.. toctree::
   :maxdepth: 3

.. highlight:: lua


Introduction
************

LuaUnit is a unit-testing framework for Lua. It allows you 
to write test functions and test classes with test methods, combined with 
setup/teardown functionality. A wide range of assertions are supported.

LuaUnit supports several output format, like Junit or TAP, for easier integration
into Continuous Integration platforms (Jenkins, Maven, ...) . The integrated command-line 
options provide a flexible interface to select tests by name or patterns, control output 
format, set verbosity, ...

Platform support
================

LuaUnit works with Lua 5.1, LuaJIT 2.0, LuaJIT 2.1 beta, Lua 5.2 and Lua 5.3 . It is tested on Windows Seven, Windows Server 2012 R2 (x64) and Ubuntu 14.04 (see 
continuous build results on `Travis-CI`_  and `AppVeyor`_  ) and should work on all platforms supported by Lua.
It has no other dependency than Lua itself.


.. _Travis-CI: https://travis-ci.org/bluebird75/luaunit
.. _AppVeyor: https://ci.appveyor.com/project/bluebird75/luaunit/history

LuaUnit is packed into a single-file. To make start using it, just add the file to your project. Other installation methods are described in the `README.md`_ file.

.. _README.md: https://github.com/bluebird75/luaunit

LuaUnit is maintained on github:
https://github.com/bluebird75/luaunit

It is released under the BSD license.


Upgrade note
================

**Important note when upgrading to version 3.1 and above** : there is a break of backward compatibility in version 3.1, assertions functions are no longer exported directly to the global namespace. See :ref:`luaunit-global-asserts` on how to adjust or restore previous behavior.


LuaUnit development
===================

See :ref:`developing-luaunit`

Version and Changelog
=====================
This documentation describes the functionality of LuaUnit v3.2 .

New in version 3.2 - 12. Jul 2016
---------------------------------
* Add command-line option to stop on first error or failure
* Distinguish between failures (failed assertion) and errors
* Support for new versions: Lua 5.3 and LuaJIT (2.0, 2.1 beta)
* Validation of all lua versions on Travis CI and AppVeyor
* Add compatibility layer with forked luaunit v2.x
* Added documentation about development process
* Improved support for table containing keys of type table
* Small bug fixes, several internal improvements
* Available with a Luarock package

New in version 3.1 - 10. Mar 2015
---------------------------------
* luaunit no longer pollutes global namespace, unless defining EXPORT_ASSERT_TO_GLOBALS to true
* fixes and validation of JUnit XML generation
* strip luaunit internal information from stacktrace
* general improvements of test results with duration and other details
* improve printing for tables, with an option to always print table id
* fix printing of recursive tables 

**Important note when upgrading to version 3.1** : assertions functions are
no longer exported directly to the global namespace. See :ref:`luaunit-global-asserts`

New in version 3.0 - 9. Oct 2014
--------------------------------

Because LuaUnit was forked and released as some 2.x version, version number
is now jumping to 3.0 . 

* full documentation available in text, html and pdf at read-the-docs.org
* new output format: JUnit, compatible with Bamboo and other CI platforms
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
* add TAP output format for integration into Jenkins
* official repository now on github


New in version 1.3 - 30. Oct 2007
---------------------------------
* port to lua 5.1
* iterate over the test classes, methods and functions in the alphabetical order
* change the default order of expected, actual in assertEquals (adjustable with USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS).


Version 1.2 - 13. Jun 2005  
---------------------------------
* first public release


Version 1.1
------------
* move global variables to internal variables
* assertion order is configurable between expected/actual or actual/expected
* new assertion to check that a function call returns an error
* display the calling stack when an error is spotted
* two verbosity level, like in python unittest



Getting started
***************

Setting up your test script
===========================

To get started, create your file *test_something.lua* . 

The script should import LuaUnit::

    luaunit = require('luaunit')

The last line executes your script with LuaUnit and exit with the
proper error code::

    os.exit( luaunit.LuaUnit.run() )

Now, run your file with::

    lua test_something.lua

It prints something like::

    Ran 0 tests in 0 seconds
    OK    

Now, your testing framework is in place, you can start writing tests.

Writing tests
=============

LuaUnit scans all variables that start with *test* or *Test*. 
If they are functions, or if they are tables that contain
functions that start with *test* or *Test*, they are run as part of the test suite.

So just write a function whose name starts with test. Inside test functions, use the assertions functions provided by LuaUnit, such
as :func:`assertEquals`.

Let's see that in practice.

Suppose you want to test the following add function::

    function add(v1,v2)
        -- add positive numbers
        -- return 0 if any of the numbers are 0
        -- error if any of the two numbers are negative
        if v1 < 0 or v2 < 0 then
            error('Can only add positive or null numbers, received '..v1..' and '..v2)
        end
        if v1 == 0 or v2 == 0 then
            return 0
        end
        return v1+v2
    end

You write the following tests::

    function testAddPositive()
        luaunit.assertEquals(add(1,1),2)
    end

    function testAddZero()
        luaunit.assertEquals(add(1,0),0)
        luaunit.assertEquals(add(0,5),0)
        luaunit.assertEquals(add(0,0),0)
    end


:func:`assertEquals` is the most common used assertion function. It simply
verifies that both argument are equals, in the order actual value, expected value.

Rerun your test script (-v is to activate a more verbose output) ::

    lua test_something.lua -v

It now prints::

    Started on 03/10/15 16:45:41
        TestAdd.testAddPositive ... Ok
        TestAdd.testAddZero ... Ok
    =========================================================
    Ran 2 tests in 0.010 seconds
    OK

You always have:

* the date at which the test suite was started
* the group to which the function belongs (usually, the name of the function table, and *<TestFunctions>* for all direct test functions)
* the name of the function being executed
* a report at the end, with number of executed test, number of non selected tests, number of failures, number of errors (if any) and duration.

The difference between failures and errors are:

* luaunit assertion functions generate failures
* any unexpected error during execution generates an error
* failures or errors during setup() or teardown() always generate errors


You also want to test that when the function receives negative numbers, it generates an error. Use
:func:`assertError` or even better, :func:`assertErrorMsgContains` to also validate the content
of the error message. There are other types or error checking functions, see :ref:`assert-error` . Here
we use :func:`assertErrorMsgContains` . First argument is the expected message, then the function to call
and the optional arguments::

    function testAddError()
        luaunit.assertErrorMsgContains('Can only add positive or null numbers, received 2 and -3', add, 2, -3)
    end

Now, suppose we also have the following function to test::

    function adder(v)
        -- return a function that adds v to its argument using add
        function closure( x ) return x+v end
        return closure
    end

We want to test the type of the value returned by adder and its behavior. LuaUnit
provides assertion for type testing (see :ref:`assert-type`). In this case, we use
:func:`assertIsFunction`::

    function testAdder()
        f = adder(3)
        luaunit.assertIsFunction( f )
        luaunit.assertEquals( f(2), 5 )
    end

Grouping tests, setup/teardown functionality
=====================================================

When the number of tests starts to grow, you usually organise them
into separate groups. You can do that with LuaUnit by putting them
inside a table (whose name must start with *Test* or *test* ).

For example, assume we have a second function to test::

    function div(v1,v2)
        -- divide positive numbers
        -- return 0 if any of the numbers are 0
        -- error if any of the two numbers are negative
        if v1 < 0 or v2 < 0 then
            error('Can only divide positive or null numbers, received '..v1..' and '..v2)
        end
        if v1 == 0 or v2 == 0 then
            return 0
        end
        return v1/v2
    end

We move the tests related to the function add into their own table::

    TestAdd = {}
        function TestAdd:testAddPositive()
            luaunit.assertEquals(add(1,1),2)
        end

        function TestAdd:testAddZero()
            luaunit.assertEquals(add(1,0),0)
            luaunit.assertEquals(add(0,5),0)
            luaunit.assertEquals(add(0,0),0)
        end

        function TestAdd:testAddError()
            luaunit.assertErrorMsgContains('Can only add positive or null numbers, received 2 and -3', add, 2, -3)
        end

        function TestAdd:testAdder()
            f = adder(3)
            luaunit.assertIsFunction( f )
            luaunit.assertEquals( f(2), 5 )
        end
    -- end of table TestAdd

Then we create a second set of tests for div::

    TestDiv = {}
        function TestDiv:testDivPositive()
            luaunit.assertEquals(div(4,2),2)
        end

        function TestDiv:testDivZero()
            luaunit.assertEquals(div(4,0),0)
            luaunit.assertEquals(div(0,5),0)
            luaunit.assertEquals(div(0,0),0)
        end

        function TestDiv:testDivError()
            luaunit.assertErrorMsgContains('Can only divide positive or null numbers, received 2 and -3', div, 2, -3)
        end
    -- end of table TestDiv

Execution of the test suite now looks like this::

    Started on 03/10/15 16:47:33
        TestAdd.testAddError ... Ok
        TestAdd.testAddPositive ... Ok
        TestAdd.testAddZero ... Ok
        TestAdd.testAdder ... Ok
        TestDiv.testDivError ... Ok
        TestDiv.testDivPositive ... Ok
        TestDiv.testDivZero ... Ok
    =========================================================
    Ran 7 tests in 0.010 seconds
    OK


When tests are defined in tables, you can optionally define two special
functions, *setUp()* and *tearDown()*, which will be executed
respectively before and after every test.

These function may be used to create specific resources for the
test being executed and cleanup the test environment.

For a practical example, imagine that we have a *log()* function
that writes strings to a log file on disk. The file is created
upon first usage of the function, and the filename is defined
by calling the function *initLog()*.

The tests for these functions would take advantage of the *setup/teardown*
functionality to prepare a log filename shared
by all tests, make sure that all tests start with a non existing
log file name, and erase the log filename after every test::

    TestLogger = {}
        function TestLogger:setUp()
            -- define the fname to use for logging
            self.fname = 'mytmplog.log'
            -- make sure the file does not already exists
            os.remove(self.fname)
        end

        function TestLogger:testLoggerCreatesFile()
            initLog(self.fname)
            log('toto')
            -- make sure that our log file was created
            f = io.open(self.fname, 'r')
            luaunit.assertNotNil( f )
            f:close()
        end

        function TestLogger:tearDown()
            -- cleanup our log file after all tests
            os.remove(self.fname)
        end

.. Note::

    *Errors generated during execution of setUp() or tearDown()
    functions are considered test failures.*


.. Note::

    *For compatibility with luaunit v2 and other lua unit-test frameworks, 
    setUp() and tearDown() may also be named setup(), SetUp(), Setup(), teardown(), TearDown(), Teardown().*


Using the command-line
======================

You can control the LuaUnit execution from the command-line:

**Output format**

Choose the test output format with ``-o`` or ``--output``. Available formats are:

* text: the default output format
* nil: no output at all
* TAP: TAP format
* junit: output junit xml

Example of non-verbose text format::

    $ lua doc/test_something.lua
    .......
    Ran 7 tests in 0.002 seconds
    OK


Example of TAP format::

    $ lua doc/test_something.lua -o TAP
    1..7
    # Started on 03/10/15 16:50:09
    # Starting class: TestAdd
    ok     1        TestAdd.testAddError
    ok     2        TestAdd.testAddPositive
    ok     3        TestAdd.testAddZero
    ok     4        TestAdd.testAdder
    # Starting class: TestDiv
    ok     5        TestDiv.testDivError
    ok     6        TestDiv.testDivPositive
    ok     7        TestDiv.testDivZero
    # Ran 7 tests in 0.022 seconds, 7 successes, 0 failures



**List of tests to run**

You can list some test names on the command-line to run only those tests.
The name must be the exact match of either the test table, the test function or the test table
and the test method. The option may be repeated.

Example::

    -- Run all TestAdd table tests and one test of TestDiv table.
    $ lua doc/test_something.lua TestAdd TestDiv.testDivError -v
    Started on 03/10/15 16:52:20
        TestAdd.testAddError ... Ok
        TestAdd.testAddPositive ... Ok
        TestAdd.testAddZero ... Ok
        TestAdd.testAdder ... Ok
        TestDiv.testDivError ... Ok
    =========================================================
    Ran 5 tests in 0.000 seconds
    OK

**Filtering tests**

The most flexible approach for selecting tests to run is to use a pattern. With
``--pattern`` or ``-p``, you can provide a lua pattern and only the tests that contain
the pattern will actually be run.

Example::

    -- Run all tests of zero testing and error testing
    -- by using the magic character .
    lua my_test_suite.lua -v -p Err.r -p Z.ro

For our test suite, it gives the following output::

    Started on 03/10/15 16:48:29
        TestAdd.testAddError ... Ok
        TestAdd.testAddZero ... Ok
        TestDiv.testDivError ... Ok
        TestDiv.testDivZero ... Ok
    =========================================================
    Ran 4 tests in 0.010 seconds
    OK (ignored=3)

The number of tests ignored by the selection is printed, along
with the test result. The pattern can be any lua pattern. Be sure to exclude all magic
characters with % (like -+?*) and protect your pattern from the shell
interpretation by putting it in quotes.

Conclusion
==========

You now know enough of LuaUnit to start writing your test suite. Check
the reference documentation for a complete list of
assertions, command-line options and specific behavior.


.. _reference-documentation:

Reference documentation
***********************

.. _luaunit-global-asserts:

Enabling global or module-level functions
=========================================

Versions of LuaUnit before version 3.1 would export all assertions functions to the global namespace. A typical
lua test file would look like this:

.. code-block:: lua

    require('luaunit')

    TestToto = {} --class

        function TestToto:test1_withFailure()
            local a = 1
            assertEquals( a , 1 )
            -- will fail
            assertEquals( a , 2 )
        end

    [...]

However, this is an obsolete practice in Lua. It is now recommended to keep all functions inside the module. Starting
from version 3.1 LuaUnit follows this practice and the code should be adapted to look like this:

.. code-block:: lua

    -- the imported module must be stored
    luaunit = require('luaunit')

    TestToto = {} --class

        function TestToto:test1_withFailure()
            local a = 1
            luaunit.assertEquals( a , 1 )
            -- will fail
            luaunit.assertEquals( a , 2 )
        end

    [...]

If you prefer the old way, LuaUnit can continue to export assertions functions if you set the following
global variable **prior** to importing LuaUnit:

.. code-block:: lua

    -- this works
    EXPORT_ASSERT_TO_GLOBALS = true
    require('luaunit')

    TestToto = {} --class

        function TestToto:test1_withFailure()
            local a = 1
            assertEquals( a , 1 )
            -- will fail
            assertEquals( a , 2 )
        end

    [...]


.. _luaunit-run:

LuaUnit.run() function
======================

**Return value**

Normally, you should run your test suite with the following line::

    os.exit(luaunit.LuaUnit.run())

The *run()* function returns the number of failures of the test suite. This is
good for an exit code, 0 meaning success.


**Arguments**

If no arguments are supplied, it parses the command-line arguments of the script
and interpret them. If arguments are supplied to the function, they are parsed
instead of the command-line. It uses the same syntax.

Example::

    -- execute tests matching the 'withXY' pattern
    os.exit(luaunit.LuaUnit.run('--pattern', 'withXY'))


**Choice of tests**

If test names were supplied, only those
tests are executed. When test names are supplied, they don't have
to start with *test*, they are run anyway.

If no test names were supplied, a general test collection process starts
under the following rules:

* all variable starting with *test* or *Test* are scanned. 
* if the variable is a function it is collected for testing
* if the variable is a table:

    * all keys starting with *test* or *Test* are collected (provided that they are functions)
    * keys with name *setUp* and *tearDown* are also collected

If one or more pattern were supplied, the test are then filtered according the
pattern(s). Only the test that match the pattern(s) are actually executed.


**setup and teardown**

The function *setUp()* is executed before each test if it exists in the table. 
The function *tearDown()* is executed after every test if it exists in the table.

.. Note::
    *tearDown()* is always executed if it exists, even if there was a failure in the test or in the *setUp()* function.
    Failures in *setUp()* or *tearDown()* are considered as a general test failures.


LuaUnit.runSuite() function
==============================

If you want to keep the flexibility of the command-line parsing, but want to force
some parameters, like the output format, you must use a slightly different syntax::

    lu = luaunit.LuaUnit.new()
    lu:setOutputType("tap")
    os.exit( lu:runSuite() )

*runSuite()* behaves like *run()* except that it must be started
with a LuaUnit instance as first argument, and it will use the LuaUnit
instance settings.
  

.. _command-line:

Command-line options
====================

Usage: lua <your_test_suite.lua> [options] [testname1 [testname2] 

**Test names**

When no test names are supplied, all tests are collected. 

The syntax for supplying test names can be either: name of the function, name of the table
or name of the table + '.' + name of the function. Only the supplied tests will be executed.

**Selecting output format**

Choose the output format with the syntax ``-o FORMAT`` or ``--output FORMAT``.

Formats available:

* ``text``: the default output format of LuaUnit
* ``nil``: no output at all
* ``tap``: output compatible with the `Test Anything Protocol`_ 
* ``junit``: output compatible with the *JUnit xml* format (used by many CI platforms)

.. _Test Anything Protocol: http://testanything.org/

.. Warning:: 

    In the JUnit format, a destination filename must be supplied with ``--name`` or ``-n``

**Destination filename**

When using the JUnit format, the test suites writes an XML file with the test results. The
file name is mandatory and must be supplied with: ``--name FILENAME`` or ``-n FILENAME``

**Selecting tests with patterns**

You select a subset of tests by specifying one or more filter patterns, 
with ``-p PATTERN`` or ``--pattern PATTERN``.

The pattern is looked for on the full test name *TestTable.testMethod* . Only the tests that
actually match the pattern are selected. When specifying more than one pattern,
they are tried one by one until the name matches (OR combination).

Make sure you esape magic chars like ``+?-*`` with ``%`` .

**Stopping on first error or failure**

If --failure or -f is passed as an option, LuaUnit will stop on the first failure or error and display the test results.

If --error or -e is passed as an option, LuaUnit will stop on the first error (but continue on failures).


**Other Options:**

*  ``-h``, ``--help``: display the command-line help.
*  ``--version``: display the version information
*  ``-v``, ``--verbose``: Increase the output verbosity. The exact effect depends on the output format. May be specified multiple times.
*  ``-q``, ``--quiet``:  Set verbosity to minimum. The exact effect depends on the output format.


.. _assertions-label:

Assertions functions
=====================
You will now find the list of all assertion functions. For all functions, When an assertion fails, the failure
message tries to be as informative as possible, by displaying the expectation and value that caused the failure.

.. Note:: see :ref:`table-printing` and :ref:`comparing-table-keys-table` for more dealing with recursive tables and tables containing keys of type table.


.. _assert-equality:

Equality assertions
----------------------
All equality assertions functions take two arguments, in the order 
*actual value* then *expected value*. Some people are more familiar
with the order *expected value* then *actual value*. It is possible to configure
LuaUnit to use the opposite order for all equality assertions, by setting up a module
variable:

.. code-block:: lua

    luaunit.ORDER_ACTUAL_EXPECTED=false

The order only matters for the message that is displayed in case of failures. It does
not influence the test itself.


.. function:: assertEquals(actual, expected)

    **Alias**: *assert_equals()*

    Assert that two values are equal. 

    For tables, the comparison is a deep comparison :

    * number of elements must be the same
    * tables must contain the same keys
    * each key must contain the same values. The values
      are also compared recursively with deep comparison.

    LuaUnit provides other table-related assertions, see :ref:`assert-table`

.. function:: assertNotEquals(actual, expected)

    **Alias**: *assert_not_equals()*

    Assert that two values are different. The assertion
    fails if the two values are identical.

    It also uses table deep comparison.

.. function:: assertAlmostEquals( actual, expected, margin )

    **Alias**: *assert_almost_equals()*

    Assert that two floating point numbers are almost equal.

    When comparing floating point numbers, strict equality does not work.
    Computer arithmetic is so that an operation that mathematically
    yields 1.00000000 might yield 0.999999999999 in lua . That's why you
    need an *almost equals* comparison, where you specify the error margin.
    
.. function:: assertNotAlmostEquals( actual, expected, margin )

    **Alias**: *assert_not_almost_equals()*

    Assert that two floating point numbers are not almost equal.
    
.. _assert-value:

Value assertions
----------------------
.. function:: assertTrue(value)

    **Alias**: *assert_true()*

    Assert that a given value compares to true. Lua coercion rules are applied
    so that values like ``0``, ``""``, ``1.17`` all compare to *true*.
    
.. function:: assertFalse(value)

    **Alias**: *assert_false()*

    Assert that a given value compares to false. Lua coercion rules are applied
    so that only *nil* and *false* all compare to *false*.
    
.. function:: assertNil(value)

    **Aliases**: *assert_nil()*, *assertIsNil()*, *assert_is_nil()*

    Assert that a given value is *nil* .
    
.. function:: assertNotNil(value)

    **Aliases**: *assert_not_nil()*, *assertNotIsNil()*, *assert_not_is_nil()*

    Assert that a given value is not *nil* . Lua coercion rules are applied
    so that values like ``0``, ``""``, ``false`` all validate the assertion.
    
.. function:: assertIs(actual, expected)

    **Alias**: *assert_is()*

    Assert that two variables are identical. For string, numbers, boolean and for nil, 
    this gives the same result as :func:`assertEquals` . For the other types, identity
    means that the two variables refer to the same object. 

    **Example :**

.. code-block:: lua

        s1='toto'
        s2='to'..'to'
        t1={1,2}
        t2={1,2}

        luaunit.assertIs(s1,s1) -- ok
        luaunit.assertIs(s1,s2) -- ok
        luaunit.assertIs(t1,t1) -- ok
        luaunit.assertIs(t1,t2) -- fail
    
.. function:: assertNotIs(actual, expected)

    **Alias**: *assert_not_is()*

    Assert that two variables are not identical, in the sense that they do not
    refer to the same value. See :func:`assertIs` for more details.
    
.. _assert-string:

String assertions
--------------------------

Assertions related to string and patterns.

.. function:: assertStrContains( str, sub [, useRe] )

    **Alias**: *assert_str_contains()*

    Assert that a string contains the given substring or pattern. 

    By default, substring is searched in the string. If *useRe*
    is provided and is true, *sub* is treated as a pattern which
    is searched inside the string *str* .
    
.. function:: assertStrIContains( str, sub )

    **Alias**: *assert_str_icontains()*

    Assert that a string contains the given substring, irrespective of the case. 

    Not that unlike :func:`assertStrcontains`, you can not search for a pattern.


.. function:: assertNotStrContains( str, sub, useRe )

    **Alias**: *assert_not_str_contains()*

    Assert that a string does not contain a given substring or pattern.

    By default, substring is searched in the string. If *useRe*
    is provided and is true, *sub* is treated as a pattern which
    is searched inside the string *str* .
    
.. function:: assertNotStrIContains( str, sub )

    **Alias**: *assert_not_str_icontains()*

    Assert that a string does not contain the given substring, irrespective of the case. 

    Not that unlike :func:`assertNotStrcontains`, you can not search for a pattern.

.. function:: assertStrMatches( str, pattern [, start [, final] ] )

    **Alias**: *assert_str_matches()*

    Assert that a string matches the full pattern *pattern*.

    If *start* and *final* are not provided or are *nil*, the pattern must match the full string, from start to end. The
    functions allows to specify the expected start and end position of the pattern in the string.
    

.. _assert-error:

Error assertions
--------------------------
Error related assertions, to verify error generation and error messages.

.. function:: assertError( func, ...)

    **Alias**: *assert_error()*

    Assert that calling functions *func* with the arguments yields an error. If the
    function does not yield an error, the assertion fails.

    Note that the error message itself is not checked, which means that this function
    does not distinguish between the legitimate error that you expect and another error
    that might be triggered by mistake.

    The next functions provide a better approach to error testing, by checking
    explicitly the error message content.

.. Note::

    When testing LuaUnit, switching from *assertError()* to  *assertErrorMsgEquals()*
    revealed quite a few bugs!
    
.. function:: assertErrorMsgEquals( expectedMsg, func, ... )

    **Alias**: *assert_error_msg_equals()*

    Assert that calling function *func* will generate exactly the given error message. If the
    function does not yield an error, or if the error message is not identical, the assertion fails.

    Be careful when using this function that error messages usually contain the file name and
    line number information of where the error was generated. This is usually inconvenient. To 
    ignore the filename and line number information, you can either use a pattern with :func:`assertErrorMsgMatches`
    or simply check for the message containt with :func:`assertErrorMsgContains` .
    
.. function:: assertErrorMsgContains( partialMsg, func, ... )

    **Alias**: *assert_error_msg_contains()*

    Assert that calling function *func* will generate an error message containing *partialMsg* . If the
    function does not yield an error, or if the expected message is not contained in the error message, the 
    assertion fails.
    
.. function:: assertErrorMsgMatches( expectedPattern, func, ... )

    **Alias**: *assert_error_msg_matches()*

    Assert that calling function *func* will generate an error message matching *expectedPattern* . If the
    function does not yield an error, or if the error message does not match the provided patternm the
    assertion fails.

    Note that matching is done from the start to the end of the error message. Be sure to escape magic all magic
    characters with ``%`` (like ``-+.?*``) .
    

.. _assert-type:

Type assertions
--------------------------

    The following functions all perform type checking on their argument. If the
    received value is not of the right type, the failure message will contain
    the expected type, the received type and the received value to help you
    identify better the problem.

.. function:: assertIsNumber(value)

    **Aliases**: *assertNumber()*, *assert_is_number()*, *assert_number()*

    Assert that the argument is a number (integer or float)
    
.. function:: assertIsString(value)

    **Aliases**: *assertString()*, *assert_is_string()*, *assert_string()*

    Assert that the argument is a string.
    
.. function:: assertIsTable(value)

    **Aliases**: *assertTable()*, *assert_is_table()*, *assert_table()*

    Assert that the argument is a table.
    
.. function:: assertIsBoolean(value)

    **Aliases**: *assertBoolean()*, *assert_is_boolean()*, *assert_boolean()*

    Assert that the argument is a boolean.
    
.. function:: assertIsNil(value)

    **Aliases**: *assertNil()*, *assert_is_nil()*, *assert_nil()*

    Assert that the argument is a nil.
    
.. function:: assertIsFunction(value)

    **Aliases**: *assertFunction()*, *assert_is_function()*, *assert_function()*

    Assert that the argument is a function.
    
.. function:: assertIsUserdata(value)

    **Aliases**: *assertUserdata()*, *assert_is_userdata()*, *assert_userdata()*

    Assert that the argument is a userdata.
    
.. function:: assertIsCoroutine(value)

    **Aliases**: *assertCoroutine()*, *assert_is_coroutine()*, *assert_coroutine()*, *assertIsThread()*, *assertThread()*, *assert_is_thread()*, *assert_thread()*

    Assert that the argument is a coroutine (an object with type *thread* ).
    
.. _assert-table:

Table assertions
--------------------------

.. function:: assertItemsEquals(actual, expected)

    **Alias**: *assert_items_equals()*

    Assert that two tables contain the same items, irrespective of their keys.

    This function is practical for example if you want to compare two lists but
    where items are not in the same order:

.. code-block:: lua

        luaunit.assertItemsEquals( {1,2,3}, {3,2,1} ) -- assertion succeeds

..

    The comparison is not recursive on the items: if any of the items are tables,
    they are compared using table equality (like as in :func:`assertEquals` ), where
    the key matters.


.. code-block:: lua

        luaunit.assertItemsEquals( {1,{2,3},4}, {4,{3,2,},1} ) -- assertion fails because {2,3} ~= {3,2}


.. _table-printing:

More on table printing
===========================

When asserting tables equality, by default, the table content is printed in case of failures. LuaUnit tries to print
tables in a readable format. It is 
possible to always display the table id along with the content, by setting a module parameter PRINT_TABLE_REF_IN_ERROR_MSG . This
helps identifying tables:

.. code-block:: lua

    local lu = require('luaunit')

    local t1 = {1,2,3}
    -- normally, t1 is dispalyed as: "{1,2,3}"

    -- if setting this:
    lu.PRINT_TABLE_REF_IN_ERROR_MSG = true

    -- display of table t1 becomes: "<table: 0x29ab56> {1,2,3}"


.. Note :: table loops

    When displaying table content, it is possible to encounter loops, if for example two table references eachother. In such
    cases, LuaUnit display the full table content once, along with the table id, and displays only the table id for the looping
    reference.

**Example:** displaying a table with reference loop

.. code-block:: lua

    local t1 = {}
    local t2 = {}
    t1.t2 = t2
    t1.a = {1,2,3}
    t2.t1 = t1

    -- when displaying table t1:
    --   table t1 inside t2 is only displayed by its id because t1 is already being displayed
    --   table t2 is displayed along with its id because it is part of a loop.
    -- t1: "<table: 0x29ab56> { a={1,2,3}, t2=<table: 0x27ab23> {t1=<table: 0x29ab56>} }"


.. _comparing-table-keys-table:

Comparing tables with keys of type table
===========================================


This is a very uncommon scenario but there are a few programs out there which use tables as keys for other tables. LuaUnit has been adjusted to deal intelligently with this scenario.

A small code block is worth a thousand pictures :

.. code-block:: lua

    local lu = require('luaunit')

    -- let's define two tables
    t1 = { 1, 2 }
    t2 = { 1, 2 }
    lu.assertEquals( t1, t2 ) -- succeeds

    -- let's define three tables, with the two above tables as keys
    t3 = { t1='a' }
    t4 = { t2='a' }
    t5 = { t2='a' }

There are two ways to treat comparison of tables t3 and t4:

**Method 1: table keys are compared by content**

* t3 contain one key: t1
* t4 contain one key: t2, which has exactly the same content as t1
* the two keys compare equally with assertEquals, so assertEquals( t3, t4 ) succeeds

**Method 2: table keys are compared by reference**

* t3 contain one key: t1
* t4 contain one key: t2, which is not the same table as t1, its reference is different
* the two keys are different because t1 is a different object than t2 so assertEquals( t3, t4 ) fails

Whether method 1 or method 2 is more appropriate is up for debate.

LuaUnit has been adjusted to support both scenarios, with the config variable: *TABLE_EQUALS_KEYBYCONTENT*

* TABLE_EQUALS_KEYBYCONTENT = true (default): method 1 - table keys compared by content
* TABLE_EQUALS_KEYBYCONTENT = false: method 2 - table keys compared by reference

In any case, assertEquals( t4, t5 ) always succeeds.

To adjust the config, change it into the luaunit table before running any tests:


.. code-block:: lua

    local lu = require('luaunit')

    -- define all your tests
    -- ...

    lu.TABLE_EQUALS_KEYBYCONTENT = false
    -- run your tests:
    os.exit( lu.LuaUnit.run() )

.. _developing-luaunit:

Developing LuaUnit
******************

Development ecosystem
======================

LuaUnit is developed on `Github`_.

.. _Github: https://github.com/bluebird75/luaunit

Bugs or feature requests should be reported using `GitHub issues`_.

.. _Github issues: https://github.com/bluebird75/luaunit/issues

Usage and development may be discussed on `LuaUnit mailing-list`_ . If you are using LuaUnit for your
project, please drop us an note.

.. _LuaUnit mailing-list: http://lists.freehackers.org/list/luaunit%40freehackers.org/ 

It is released under the BSD license.

This documentation is available at `Read-the-docs`_.

.. _Read-the-docs: http://luaunit.readthedocs.org/en/latest/


Contributing
=============
You may contribute to LuaUnit by reporting bugs, fixing reported bugs or developing new features.

Some issues on github are marked with label *enhancement*. Feel free to pick up such tasks and implement them.

Changes should be proposed as *Pull Requests* on github.

Unit-tests
-------------------
All proposed changes should pass all unit-tests and if needed, add more unit-tests to cover the bug or the new functionality. Usage is pretty simple:

.. code-block:: shell

    $ lua run_unit_tests.lua
    ................................................................................
    ...............................
    Ran 111 tests in 0.120 seconds
    OK


Functional tests
-------------------
Functional tests also exist to validate LuaUnit. Their management is slightly more complicated. 

The main goal of functional tests is to validate that LuaUnit output has not been altered. Since LuaUnit supports some standard compliant output (TAP, junitxml), this is very important (and it has been broken in the past)

Functional tests perform the following actions:

* Run the 2 suites: example_with_luaunit.lua, test_with_err_fail_pass.lua (with various options to have successe, failure and/or errors)
* Run every suite with all output format, all verbosity
* Validate the XML output with jenkins/hudson and junit schema
* Compare the results with the previous output ( archived in test/ref ), with some tricks to make the comparison possible :

    * adjustment of the file separator to use the same output on Windows and Unix
    * date and test duration is zeroed so that it does not impact the comparison
    * adjust the stack trace format which has changed between Lua 5.1, 5.2 and 5.3

* Run some legacy suites or tricky output to manage and verify output: test_with_xml.lua, , compat_luaunit_v2x.lua, legacy_example_with_luaunit.lua


For functional tests to run, *diff* must be available on the command line. *xmllint* is needed to perform the xml validation but
this step is skipped if *xmllint* can not be found.

When functional tests work well, it looks like this:

.. code-block:: shell

    $ lua run_functional_tests.lua
    ...............
    Ran 15 tests in 9.676 seconds
    OK


When functional test fail, a diff of the comparison between the reference output and the current output is displayed (it can be quite 
long). The list of faulty files is summed-up at the end.

Modifying reference files for functional tests
-----------------------------------------------
The script run_functional_tests.lua supports a --update option, with an optional argument.

* *--update* without argument **overwrites all reference output** with the current output. Use only if you know what you are doing, this is usually a very bad idea!

* The following argument overwrite a specific subset of reference files, select the one that fits your change:

    *  TestXml: XML output of test_with_xml
    *  ExampleXml: XML output of example_with_luaunit
    *  ExampleTap: TAP output of example_with_luaunit
    *  ExampleText: text output of example_with_luaunit
    *  ExampleNil: nil output of example_with_luaunit
    *  ErrFailPassText: text output of test_with_err_fail_pass
    *  ErrFailPassTap: TAP output of test_with_err_fail_pass
    *  ErrFailPassXml: XML output of test_with_err_fail_pass
    *  StopOnError: errFailPassTextStopOnError-1.txt, -2.txt, -3.txt, -4.txt


For example to record a change in the test_with_err_fail_pass output

.. code-block:: shell

    $ lua run_functional_tests.lua --update ErrFailPassXml ErrFailPassTap ErrFailPassText

    >>>>>>> Generating test/ref/errFailPassXmlDefault.txt
    >>>>>>> Generating test/ref/errFailPassXmlDefault-success.txt
    >>>>>>> Generating test/ref/errFailPassXmlDefault-failures.txt
    >>>>>>> Generating test/ref/errFailPassXmlQuiet.txt
    >>>>>>> Generating test/ref/errFailPassXmlQuiet-success.txt
    >>>>>>> Generating test/ref/errFailPassXmlQuiet-failures.txt
    >>>>>>> Generating test/ref/errFailPassXmlVerbose.txt
    >>>>>>> Generating test/ref/errFailPassXmlVerbose-success.txt
    >>>>>>> Generating test/ref/errFailPassXmlVerbose-failures.txt
    >>>>>>> Generating test/ref/errFailPassTapDefault.txt
    >>>>>>> Generating test/ref/errFailPassTapDefault-success.txt
    >>>>>>> Generating test/ref/errFailPassTapDefault-failures.txt
    >>>>>>> Generating test/ref/errFailPassTapQuiet.txt
    >>>>>>> Generating test/ref/errFailPassTapQuiet-success.txt
    >>>>>>> Generating test/ref/errFailPassTapQuiet-failures.txt
    >>>>>>> Generating test/ref/errFailPassTapVerbose.txt
    >>>>>>> Generating test/ref/errFailPassTapVerbose-success.txt
    >>>>>>> Generating test/ref/errFailPassTapVerbose-failures.txt
    >>>>>>> Generating test/ref/errFailPassTextDefault.txt
    >>>>>>> Generating test/ref/errFailPassTextDefault-success.txt
    >>>>>>> Generating test/ref/errFailPassTextDefault-failures.txt
    >>>>>>> Generating test/ref/errFailPassTextQuiet.txt
    >>>>>>> Generating test/ref/errFailPassTextQuiet-success.txt
    >>>>>>> Generating test/ref/errFailPassTextQuiet-failures.txt
    >>>>>>> Generating test/ref/errFailPassTextVerbose.txt
    >>>>>>> Generating test/ref/errFailPassTextVerbose-success.txt
    >>>>>>> Generating test/ref/errFailPassTextVerbose-failures.txt
    $

You can then commit the new files into git.

.. Note :: how to commit updated reference outputs

    When committing those changes into git, please use if possible an
    intelligent git committing tool to commit only the interesting changes.
    With SourceTree for example, in case of XML changes, I can select only the
    lines relevant to the change and avoid committing all the updates to test
    duration and test datestamp.



Typical failures for functional tests
---------------------------------------

Functional tests may start failing when:

1. Increasing LuaUnit version
2. Improving or breaking LuaUnit output


Index and Search page
**********************

* :ref:`genindex`
* :ref:`search`

