
.. _getting-started:

Getting started with LuaUnit
===================================

This section will guide you through a step by step usage of *LuaUnit* . The full source code
of the example below is available in the : :ref:`source_code_example` or in the file *my_test_suite.lua* 
in the doc directory.

Setting up your test script
---------------------------

To get started, create your file *my_test_suite.lua* . 

The script should import LuaUnit::

    lu = require('luaunit')

The last line executes your script with LuaUnit and exit with the
proper error code::

    os.exit( lu.LuaUnit.run() )

Now, run your file with::

    lua my_test_suite.lua

It prints something like::

    Ran 0 tests in 0.000 seconds, 0 successes, 0 failures
    OK

Now, your testing framework is in place, you can start writing tests.

Writing tests
-----------------

LuaUnit scans all variables that start with *test* or *Test*. 
If they are functions, or if they are tables that contain
functions that start with *test* or *Test*, they are run as part of the test suite.

So just write a function whose name starts with test. Inside test functions, use the assertions functions provided by LuaUnit, such
as :lua:func:`assertEquals`.

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
        lu.assertEquals(add(1,1),2)
    end

    function testAddZero()
        lu.assertEquals(add(1,0),0)
        lu.assertEquals(add(0,5),0)
        lu.assertEquals(add(0,0),0)
    end


:lua:func:`assertEquals` is the most commonly used assertion function. It 
verifies that both argument are equals, in the order actual value, expected value.

Rerun your test script (``-v`` is to activate a more verbose output)::

    $ lua my_test_suite.lua -v

It now prints::

    Started on 02/19/17 22:15:53
        TestAdd.testAddPositive ... Ok
        TestAdd.testAddZero ... Ok
    =========================================================
    Ran 2 tests in 0.003 seconds, 2 successes, 0 failures
    OK

You always have:

* the date at which the test suite was started
* the group to which the function belongs (usually, the name of the function table, and *<TestFunctions>* for all direct test functions)
* the name of the function being executed
* a report at the end, with number of executed test, number of non selected tests if any, number of failures, number of errors (if any) and duration.

The difference between failures and errors are:

* luaunit assertion functions generate failures
* any unexpected error during execution generates an error
* failures or errors during setup() or teardown() always generate errors


If we continue with our example, we also want to test that when the function receives negative numbers, it generates an error. Use
:lua:func:`assertError` or even better, :lua:func:`assertErrorMsgContains` to also validate the content
of the error message. There are other types or error checking functions, see :ref:`error-assertions` . Here
we use :lua:func:`assertErrorMsgContains` . First argument is the expected message, then the function to call
and the optional arguments::

    function testAddError()
        lu.assertErrorMsgContains('Can only add positive or null numbers, received 2 and -3', add, 2, -3)
    end

Now, suppose we also have the following function to test::

    function adder(v)
        -- return a function that adds v to its argument using add
        function closure( x ) return x+v end
        return closure
    end

We want to test the type of the value returned by adder and its behavior. LuaUnit
provides assertion for type testing (see :ref:`type-assertions` ). In this case, we use
:lua:func:`assertIsFunction`::

    function testAdder()
        f = adder(3)
        lu.assertIsFunction( f )
        lu.assertEquals( f(2), 5 )
    end

Grouping tests, setup/teardown functionality
------------------------------------------------

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
            lu.assertEquals(add(1,1),2)
        end

        function TestAdd:testAddZero()
            lu.assertEquals(add(1,0),0)
            lu.assertEquals(add(0,5),0)
            lu.assertEquals(add(0,0),0)
        end

        function TestAdd:testAddError()
            lu.assertErrorMsgContains('Can only add positive or null numbers, received 2 and -3', add, 2, -3)
        end

        function TestAdd:testAdder()
            f = adder(3)
            lu.assertIsFunction( f )
            lu.assertEquals( f(2), 5 )
        end
    -- end of table TestAdd

Then we create a second set of tests for div::

    TestDiv = {}
        function TestDiv:testDivPositive()
            lu.assertEquals(div(4,2),2)
        end

        function TestDiv:testDivZero()
            lu.assertEquals(div(4,0),0)
            lu.assertEquals(div(0,5),0)
            lu.assertEquals(div(0,0),0)
        end

        function TestDiv:testDivError()
            lu.assertErrorMsgContains('Can only divide positive or null numbers, received 2 and -3', div, 2, -3)
        end
    -- end of table TestDiv

Execution of the test suite now looks like this::

    Started on 02/19/17 22:15:53
        TestAdd.testAddError ... Ok
        TestAdd.testAddPositive ... Ok
        TestAdd.testAddZero ... Ok
        TestAdd.testAdder ... Ok
        TestDiv.testDivError ... Ok
        TestDiv.testDivPositive ... Ok
        TestDiv.testDivZero ... Ok
    =========================================================
    Ran 7 tests in 0.006 seconds, 7 successes, 0 failures
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
log file name, and delete the log filename after every test::

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
            lu.assertNotNil( f )
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
    setUp() and tearDown() may also be named setup(), SetUp(), Setup() and teardown(), TearDown(), Teardown().*


.. _Using-the-command-line:

Using the command-line
----------------------------------

You can control the LuaUnit execution from the command-line:

*Output format**

Choose the test output format with ``-o`` or ``--output``. Available formats are:

* text: the default output format
* nil: no output at all
* tap: TAP format
* junit: output junit xml

Example of non-verbose text format::

    $ lua doc/my_test_suite.lua
    .......
    Ran 7 tests in 0.003 seconds, 7 successes, 0 failures
    OK


Example of TAP format::

    $ lua doc/my_test_suite.lua -o TAP
    1..7
    # Started on 02/19/17 22:15:53
    # Starting class: TestAdd
    ok     1        TestAdd.testAddError
    ok     2        TestAdd.testAddPositive
    ok     3        TestAdd.testAddZero
    ok     4        TestAdd.testAdder
    # Starting class: TestDiv
    ok     5        TestDiv.testDivError
    ok     6        TestDiv.testDivPositive
    ok     7        TestDiv.testDivZero
    # Ran 7 tests in 0.007 seconds, 7 successes, 0 failures


Output formats may also be controlled by the following environment variables:
* LUAUNIT_OUTPUT: output format to use
* LUAUNIT_JUNIT_FNAME: for junit output format, name of the xml file

For a more detailed overview of all formats and their verbosity see the section :ref:`output-formats` .


**List of tests to run**

You can list some test names on the command-line to run only those tests.
The name must be the exact match of either the test table, the test function or the test table
and the test method. The option may be repeated.

Example::

    -- Run all TestAdd table tests and one test of TestDiv table.
    $ lua doc/my_test_suite.lua TestAdd TestDiv.testDivError -v
    Started on 02/19/17 22:15:53
        TestAdd.testAddError ... Ok
        TestAdd.testAddPositive ... Ok
        TestAdd.testAddZero ... Ok
        TestAdd.testAdder ... Ok
        TestDiv.testDivError ... Ok
    =========================================================
    Ran 5 tests in 0.003 seconds, 5 successes, 0 failures
    OK

**Including / excluding tests**

The most flexible approach for selecting tests to use the include and exclude functionality.
With ``--pattern`` or ``-p``, you can provide a lua pattern and only the tests that contain
the pattern will actually be run.

Example::

    -- Run all tests of zero testing and error testing
    -- by using the magic character .
    $ lua my_test_suite.lua -v -p Err.r -p Z.ro

For our test suite, it gives the following output::

    Started on 02/19/17 22:15:53
        TestAdd.testAddError ... Ok
        TestAdd.testAddZero ... Ok
        TestDiv.testDivError ... Ok
        TestDiv.testDivZero ... Ok
    =========================================================
    Ran 4 tests in 0.003 seconds, 4 successes, 0 failures, 3 non-selected
    OK

The number of tests ignored by the selection is printed, along
with the test result. The pattern can be any lua pattern. Be sure to exclude all magic
characters with % (like -+?*) and protect your pattern from the shell
interpretation by putting it in quotes.

You can also exclude tests that match some patterns:

Example::

    -- Run all tests except zero testing and except error testing
    $ lua my_test_suite.lua -v -x Error -x Zero

For our test suite, it gives the following output::

    Started on 02/19/17 22:29:45
        TestAdd.testAddPositive ... Ok
        TestAdd.testAdder ... Ok
        TestDiv.testDivPositive ... Ok
    =========================================================
    Ran 3 tests in 0.003 seconds, 3 successes, 0 failures, 4 non-selected
    OK

You can also combine test selection and test exclusion. See :ref:`flexible-test-selection`

Conclusion
----------

You now know enough of LuaUnit to start writing your test suite. Check
the reference documentation for a complete list of
assertions, command-line options and specific behavior.

