.. LuaUnit documentation master file, created by
   sphinx-quickstart on Thu Aug 21 21:45:55 2014.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.


,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
Welcome to LuaUnit's documentation!
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

.. toctree::
   :maxdepth: 2


Introduction
************

Luaunit is a unit-testing framework for Lua. It allows you 
to write test functions and test classes with test methods, combined with 
setup/teardown functionality. A wide range of assertions are supported.

Luaunit supports several output format, like Junit or TAP, for easier integration
into Continuous Integration platforms (Jenkins, Maven, ...) . The integrated command-line 
options provide a flexible interface to select tests by name or patterns, control output 
format, set verbosity, ...

Platform support
================

LuaUnit works with Lua 5.1 and 5.2 . It is tested on Windows XP and Ubuntu 12.04 (see 
continuous build results on travic-ci.org ) and should work on all platforms supported by lua.
It has no other dependency than lua itself. 

LuaUnit is packed into a single-file, to make it easy to use it in any projects.

Development
===========

Luaunit is developed on `Github`_.

.. _Github: https://github.com/bluebird75/luaunit

Bugs or feature requests must be reported using `GitHub issues`_.

.. _Github issues: https://github.com/bluebird75/luaunit/issues

It is released under the BSD license.

This documentation is available at `Read-the-docs`_.

.. _Read-the-docs: http://luaunit.readthedocs.org/en/latest/

Getting started
***************

Setting up your test script
===========================

To get started, create your file *test_something.lua* . 

The script should import LuaUnit::

    require('luaunit')

The last line executes your script with LuaUnit and exit with the
proper error code::

    os.exit( LuaUnit.run() )

Now, run your file with::

    lua test_something.lua

It prints something like::

    Started on 08/07/14 07:07:40
    =========================================================
    Success: 100% - 0 / 0, executed in 0.000 seconds

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
        assertEquals(add(1,1),2)
    end

    function testAddZero()
        assertEquals(add(1,0),0)
        assertEquals(add(0,5),0)
        assertEquals(add(0,0),0)
    end


:func:`assertEquals` is the most common used assertion function. It simply
verifies that both argument are equals, in the order actual value, expected value.

Rerun your test script::

    lua test_something.lua

It now prints::

    Started on 08/16/14 13:55:18
    >>>>>>>>> <TestFunctions>
    >>> testAddPositive
    >>> testAddZero

    =========================================================
    Success: 100% - 2 / 2, executed in 0.000 seconds

You always have:

* the date at which the test suite was started
* the group to which the function belongs (usually, the name of the function table, and *<TestFunctions>* for all direct test functions)
* the name of the function being executed
* a report at the end, with number of executed test, success rate and execution duration


You also want to test that when the function receives negative numbers, it generates an error. Use
:func:`assertError` or even better, :func:`assertErrorMsgContains` to also validate the content
of the error message. There are other types or error checking functions, see :ref:`assert-error` . Here
we use :func:`assertErrorMsgContains` . First argument is the expected message, then the function to call
and the optional arguments::

    function testAddError()
        assertErrorMsgContains('Can only add positive or null numbers, received 2 and -3', add, 2, -3)
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
        assertIsFunction( f )
        assertEquals( f(2), 5 )
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
            assertEquals(add(1,1),2)
        end

        function TestAdd:testAddZero()
            assertEquals(add(1,0),0)
            assertEquals(add(0,5),0)
            assertEquals(add(0,0),0)
        end

        function TestAdd:testAddError()
            assertErrorMsgContains('Can only add positive or null numbers, received 2 and -3', add, 2, -3)
        end

        function TestAdd:testAdder()
            f = adder(3)
            assertIsFunction( f )
            assertEquals( f(2), 5 )
        end
    -- end of table TestAdd

Then we create a second set of tests for div::

    TestDiv = {}
        function TestDiv:testDivPositive()
            assertEquals(div(4,2),2)
        end

        function TestDiv:testDivZero()
            assertEquals(div(4,0),0)
            assertEquals(div(0,5),0)
            assertEquals(div(0,0),0)
        end

        function TestDiv:testDivError()
            assertErrorMsgContains('Can only div positive or null numbers, received 2 and -3', div, 2, -3)
        end
    -- end of table TestDiv

Execution of the test suite now looks like this::

    Started on 08/16/14 22:05:03
    >>>>>>>>> TestAdd
    >>> TestAdd.testAddError
    >>> TestAdd.testAddPositive
    >>> TestAdd.testAddZero
    >>> TestAdd.testAdder

    >>>>>>>>> TestDiv
    >>> TestDiv.testDivError
    >>> TestDiv.testDivPositive
    >>> TestDiv.testDivZero

    =========================================================
    Success: 100% - 7 / 7, executed in 0.000 seconds


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
            assertNotNil( f )
            f:close()
        end

        function TestLogger:tearDown()
            -- cleanup our log file after all tests
            os.remove(self.fname)
        end

**Note:**
    *Errors generated during execution of setUp() or tearDown()
    functions are considered    test failures.*

Using the command-line
======================

You can control the LuaUnit execution from the command-line:

**Output format**

Choose the test output format with ``-o`` or ``--output``. Available formats are:

* text: the default output format
* nil: no output at all
* TAP: TAP format
* junit: output junit xml

Example::

    lua my_test_suite.lua -o TAP

**List of tests to run**

You can list some test names on the command-line to run only those tests.
The name must be the exact match of either the test table, the test function or the test table
and the test method. The option may be repeated.

Example::

    -- Run all TestAdd table tests and one test of TestDiv table.
    lua my_test_suite.lua TestAdd TestDiv.testDivError


**Filtering tests**

The most flexible approach for selecting tests to run is to use a pattern. With
``--pattern`` or ``-p``, you can provide a lua pattern and only the tests that contain
the pattern will actually be run.

Example::

    -- Run all tests of zero testing and error testing
    -- by using the magic character .
    lua my_test_suite.lua -p Err.r -p Z.ro

For our test suite, it gives the following output::

    Started on 08/16/14 22:38:30
    >>>>>>>>> TestAdd
    >>> TestAdd.testAddError
    >>> TestAdd.testAddZero

    >>>>>>>>> TestDiv
    >>> TestDiv.testDivError
    >>> TestDiv.testDivZero

    =========================================================
    Success: 100% - 4 / 4, executed in 0.000 seconds

The pattern can be any lua pattern. Be sure to exclude all magic
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

.. _luaunit-run:

LuaUnit.run() function
======================

**Return value**

Normally, you should run your test suite with the following line::

    os.exit(LuaUnit.run())

The *run()* function returns the number of failures of the test suite. This is
good for an exit code, 0 meaning success.


**Arguments**

If no arguments are supplied, it parses the command-line arguments of the script
and interpret them. If arguments are supplied to the function, they are parsed
instead of the command-line. It uses the same syntax.

Example::

    -- execute tests matching the 'withXY' pattern
    os.exit(LuaUnit.run('--pattern', 'withXY'))


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

Note:
    Failures in setUp() or tearDown() are considered as a general test failures.
    tearDown() is always executed if it exists, even if there was a failure in the test or in the setUp() function


LuaUnit.runSuite() function
==============================

If you want to keep the flexibility of the command-line parsing, but want to force
some parameters, like the output format, you must use a slightly different syntax::

    lu = LuaUnit.new()
    lu:setOutputType("tap")
    os.exit( lu:runSuite() )

*runSuite()* behaves like *run()* except that it must be started
with a LuaUnit instance as first argument, and it will use the LuaUnit
instance settings.
  

.. _command-line:

Command-line options
====================

Usage: lua <your_test_suite.lua> [options] [testname1 [testname2] 

**test names**

When no test names are supplied, all tests are collected. 

The syntax for supplying test names can be either: name of the function, name of the table
or name of the table + '.' + name of the function. Only the supplied tests will be executed.

**selecting output format**

Choose the output format with the syntax ``-o FORMAT`` or ``--output FORMAT``.

Formats available:

* text: the default output format of LuaUnit
* nil: no output at all
* tap: output compatible with the `Test Anything Protocol`_ 
* junit: output compatible with the *JUnit xml* format

.. _Test Anything Protocol: http://testanything.org/

**Selecting tests with patterns**

You select a subset of tests by specifying one or more filter patterns, 
with ``-p PATTERN`` or ``--pattern PATTERN``.

The pattern is looked for on the full test name *TestTable.testMethod* . Only the tests that
actually match the pattern are selected. When specifying more than one pattern,
they are tried one by one until the name matches (OR combination).

Make sure you esape magic chars like +?-* with % .


**Other Options:**

*  -h, --help: display the command-line help.
*  --version: display the version information
*  -v, --verbose: Increase the output verbosity. The exact effect depends on the output format. May be specified multiple times.
*  -q, --quiet:  Set verbosity to minimum. The exact effect depends on the output format.


.. _assertions-label:

Assertions functions
=====================

.. _assert-equality:

Equality assertions
----------------------

.. function:: assertEquals(actual, expected)

    bla bla bla
    
.. function:: assertNotEquals(actual, expected)

    bla bla bla
    
.. function:: assertAlmostEquals( actual, expected, margin )

    bla bla bla
    
.. function:: assertNotAlmostEquals( actual, expected, margin )

    bla bla bla
    
.. _assert-value:

Value assertions
----------------------
.. function:: assertTrue(value)

    bla bla bla
    
.. function:: assertFalse(value)

    bla bla bla
    
.. _assert-string:

String assertions
--------------------------
.. function:: assertStrContains( str, sub, useRe )

    bla bla bla
    
.. function:: assertStrIContains( str, sub )

    bla bla bla
    
.. function:: assertNotStrContains( str, sub, useRe )

    bla bla bla
    
.. function:: assertNotStrIContains( str, sub )

    bla bla bla
    
.. function:: assertStrMatches( str, regexp )

    bla bla bla
    

.. _assert-error:

Error assertions
--------------------------
.. function:: assertError(f, ...)

    bla bla bla
    
.. function:: assertErrorMsgEquals( expectedMsg, func, ... )

    bla bla bla
    
.. function:: assertErrorMsgContains( partialMsg, func, ... )

    bla bla bla
    
.. function:: assertErrorMsgMatches( expectedMsg, func, ... )

    bla bla bla
    

.. _assert-type:


Type assertions
--------------------------
.. function:: assertIsNumber(value)

    bla bla bla
    
.. function:: assertIsString(value)

    bla bla bla
    
.. function:: assertIsTable(value)

    bla bla bla
    
.. function:: assertIsBoolean(value)

    bla bla bla
    
.. function:: assertIsNil(value)

    bla bla bla
    
.. function:: assertIsFunction(value)

    bla bla bla
    
.. function:: assertIsUserdata(value)

    bla bla bla
    
.. function:: assertIsThread(value)

    bla bla bla
    
.. function:: assertIs(actual, expected)

    bla bla bla
    
.. function:: assertNotIs(actual, expected)

    bla bla bla
    

.. _assert-table:

Table assertions
--------------------------

.. function:: assertItemsEquals(actual, expected)

    bla bla bla
    

,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
Annex: index and search page
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

* :ref:`genindex`
* :ref:`search`

