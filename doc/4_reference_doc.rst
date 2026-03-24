
Reference documentation
***********************

Index and Search page
===========================

* :ref:`genindex`
* :ref:`search`

.. _command-line-options:

Command-line options
====================

Usage: lua <your_test_suite.lua> [options] [testname1 [testname2] ...]

**Test names**

When no test names are supplied, all tests are collected. 

The syntax for supplying test names can be either: name of the function, name of the table
or [name of the table].[name of the function]. Only the supplied tests will be executed.

Selecting tests with --pattern and --exclude is usually more flexible. See :ref:`flexible-test-selection`

**Options**

--output, -o FORMAT         Set output format to FORMAT. Possible values: text, tap, junit, nil . See :ref:`output-formats`
--name, -n FILENAME         For junit format only, mandatory name of xml file. Ignored for other formats.
--pattern, -p PATTERN       Execute all test names matching the Lua PATTERN. May be repeated to include severals patterns. See :ref:`flexible-test-selection`
--exclude, -x PATTERN       Exclude all test names matching the Lua PATTERN. May be repeated to exclude severals patterns. See :ref:`flexible-test-selection`
--test-prefix, -t prefix    Prefix for detecting test tables or functions. See :ref:`test-naming`
--test-suffix, -T suffix    Suffix for detecting test tables or functions. See :ref:`test-naming`
--method-prefix, -m prefix  Prefix for test methods. See :ref:`test-naming`
--repeat, -r NUM            Repeat all tests NUM times, e.g. to trigger the JIT. See :ref:`other-options`
--shuffle, -s               Shuffle tests before running them. See :ref:`other-options`
--error, -e                 Stop on first error. See :ref:`other-options`
--failure, -f               Stop on first failure or error. See :ref:`other-options`
--verbose, -v               Increase verbosity
--quiet, -q                 Set verbosity to minimum
--help, -h                  Print help
--version                   Version information of LuaUnit

.. _output-formats:

Output formats 
----------------------

Choose the output format with the syntax ``-o FORMAT`` or ``--output FORMAT`` or the environment variable ``LUAUNIT_OUTPUT``.

Formats available:

* ``text``: the default output format of LuaUnit
* ``tap``: output compatible with the `Test Anything Protocol`_ 
* ``junit``: output compatible with the *JUnit XML* format (used by many CI 
  platforms). The XML is written to the file provided with the ``--name`` or ``-n`` option or the environment variable ``LUAUNIT_JUNIT_FNAME``.
* ``nil``: no output at all

.. _Test Anything Protocol: http://testanything.org/

For more information on each format, see :ref:`output-formats-details`


.. _other-options:

Other options
--------------

**Stopping on first error or failure**

If ``--failure`` or ``-f`` is passed as an option, LuaUnit will stop on the first failure or error and display the test results.

If ``--error`` or ``-e`` is passed as an option, LuaUnit will stop on the first error (but continue on failures).

**Randomize test order**

If ``--shuffle`` or ``-s`` is passed as an option, LuaUnit will execute tests in random order. The randomisation works on all test functions
and methods. As a consequence test methods of a given class may be splitted into multiple location, generating several test class creation and destruction.

**Repeat test**

When using luajit, the just-in-time compiler will kick in only after a given function has been executed a sufficient number of times. To make sure
that the JIT is not introducing any bug, LuaUnit provides a way to repeat a test may times, with ``--repeat`` or ``-r`` followed by a number.

.. _flexible-test-selection:

Flexible test selection
-------------------------

LuaUnit provides very flexible way to select which tests to execute. We will illustrate this with several examples.

In the examples, we use a test suite composed of the following test funcions::

    -- class: TestAdd
    TestAdd.testAddError
    TestAdd.testAddPositive
    TestAdd.testAddZero
    TestAdd.testAdder

    -- class: TestDiv
    TestDiv.testDivError
    TestDiv.testDivPositive
    TestDiv.testDivZero


With ``--pattern`` or ``-p``, you can provide a lua pattern and only the tests that contain
the pattern will actually be run.

Example::

    -- Run all tests of zero testing and error testing
    -- by using the magic character .
    $ lua mytest_suite.lua -v -p Err.r -p Z.ro
    Started on 02/19/17 22:29:45
        TestAdd.testAddError ... Ok
        TestAdd.testAddZero ... Ok
        TestDiv.testDivError ... Ok
        TestDiv.testDivZero ... Ok
    =========================================================
    Ran 4 tests in 0.004 seconds, 4 successes, 0 failures, 3 non-selected
    OK

The number of tests ignored by the selection is printed, along
with the test result. The tests *TestAdd.testAdder testAdd.testPositive and
testDiv.testDivPositive* have been correctly ignored.

The pattern can be any lua pattern. Be sure to exclude all magic
characters with % (like ``-+?*``) and protect your pattern from the shell
interpretation by putting it in quotes.

With ``--exclude`` or ``-x``, you can provide a lua pattern of tests which should
be excluded from execution.

Example::

    -- Run all tests except zero testing and except error testing
    $ lua mytest_suite.lua -v -x Error -x Zero
    Started on 02/19/17 22:29:45
        TestAdd.testAddPositive ... Ok
        TestAdd.testAdder ... Ok
        TestDiv.testDivPositive ... Ok
    =========================================================
    Ran 3 tests in 0.003 seconds, 3 successes, 0 failures, 4 non-selected
    OK

You can also combine test selection and test exclusion. The rules are the following:

* if the first argument encountered is a inclusion pattern, the list of tests start empty
* if the first argument encountered is an exclusion pattern, the list of tests start with all tests of the suite
* each subsequent inclusion pattern will add new tests to the list
* each subsequent exclusion pattern will remove test from the list
* the final list is the list of tests executed

In pure logic term, inclusion is the equivalent of ``or match(pattern)`` and exclusion is ``and not match(pattern)`` .

Let's look at some practical examples::

    -- Add all tests which include the word Add
    -- except the test Adder
    -- and also include the Zero tests
    $ lua my_test_suite.lua -v --pattern Add --exclude Adder --pattern Zero
    Started on 02/19/17 22:29:45
        TestAdd.testAddError ... Ok
        TestAdd.testAddPositive ... Ok
        TestAdd.testAddZero ... Ok
        TestDiv.testDivZero ... Ok
    =========================================================
    Ran 4 tests in 0.003 seconds, 4 successes, 0 failures, 3 non-selected
    OK


.. _test-naming:

Test naming
--------------

The most common way to define tests is to create functions whose name starts with *test* or *Test* and/or 
tables that start with *test* or *Test* and contain functions whose name starts with *test* or *Test*. LuaUnit will 
automatically detect these functions as tests and execute them.

However, if you have a different convention, it is possible to make adjustments to this process:

* with the command-line option ``--test-prefix`` or ``-t``, you can ask LuaUnit to consider as tests only functions or 
  tables that start with a specific prefix.
* with the command-line option ``--test-suffix`` or ``-T``, you can ask LuaUnit to consider as tests only functions or 
  tables that end with a specific suffix
* with the command-line option ``--method-prefix`` or ``-m``, you can ask LuaUnit to consider as test methods only functions 
  that start with a specific prefix.

Test prefix and suffix can be used together, the list of collected tests will be the union of that either start with the given
prefix or end with the given suffix.

The test prefix, test suffix and method prefix can also be set on the LuaUnit runner object, with the attributes ``testPrefix`` and ``testSuffix``. The method prefix 
can be set with the attribute ``methodPrefix``. See :ref:`LuaUnit-runner-object` for more details.


.. _LuaUnit-runner-object:

LuaUnit runner object
=======================

The various options set on the command-line can be overridden by creating a LuaUnit runner explicitely and calling specific functions on it.

.. lua:class:: LuaUnit 

    .. lua:staticmethod:: LuaUnit.new()

        The execution of a LuaUnit test suite is controlled through a runner object. This object is created with `LuaUnit.new()` .

    .. code-block:: lua

        lu = require('luaunit')


        runner = lu.LuaUnit.new()
        -- use the runner object...
        runner.runSuite()


    .. lua:method:: setVerbosity( verbosity )

        Set the verbosity of the runner. The value is an integer ranging from lu.VERBOSITY_QUIET to lu.VERBOSITY_VERBOSE .


    .. lua:method:: setQuitOnError( quitOnError )

        Set the quit-on-first-error behavior, like the command-line `--xx`. The argument is a boolean value.


    .. lua:method:: setQuitOnFailure( quitOnFailure )

        Set the quit-on-first-failure-or-error behavior, like the command-line `--xx`. The argument is a boolean value.


    .. lua:method:: setRepeat( repeatNumber )

        Set the number of times a test function is executed, like the command-line `-xx`. The argument is an integer.


    .. lua:method:: setShuffle( shuffle )

        Set whether the test are run in randomized, like the command-line `--shuffle`. The argument is a boolean value.

    .. lua:method:: setOutputType(type [, junit_fname])

        Set the output type of the test suite. See :ref:`output-formats` for possible values. When setting the format `junit`, it
        is mandatory to set the filename receiving the xml output. This can be done by passing it as second argument of this function.

    .. lua:attribute:: testPrefix

        Prefix used for detecting test tables or functions. Default value is *test*. See :ref:`test-naming` for more details.

    .. lua:attribute:: testSuffix

        Suffix used for detecting test tables or functions. Default value is *nil*. See :ref:`test-naming` for more details.

    .. lua:attribute:: methodPrefix

        Prefix used for detecting test methods. Default value is *test*. See :ref:`test-naming` for more details.


    .. lua:method:: runSuite( [arguments] )

        This function runs the test suite.

        **Arguments**

        If no arguments are supplied, it parses the command-line arguments of the script
        and interpret them. If arguments are supplied to the function, they are parsed
        as the command-line. It uses the same syntax.

        Test names may be supplied in arguments, to execute
        only these specific tests. Note that when explicit names are provided
        LuaUnit does not require the test names to necessarily start with *test*.

        If no test names were supplied, a general test collection process is done
        and the resulting tests are executed.

        **Return value**

        It returns the number of failures and errors. On
        success 0 is returned, making is suitable for an exit code.

        .. code-block:: lua

            lu = require('luaunit')

            runner = lu.LuaUnit.new()
            os.exit(runner.runSuite())



        **Example of using pattern to select tests:**

        .. code-block:: lua

            lu = require('luaunit')

            runner = lu.LuaUnit.new()
            -- execute tests matching the 'withXY' pattern
            os.exit(runner.runSuite('--pattern', 'withXY')


        **Example of explicitly selecting tests:**

        .. code-block:: lua

            lu = require('luaunit')

            runner = lu.LuaUnit.new()
            os.exit(runner.runSuite('testABC', 'testDEF'))


    .. lua:staticmethod:: run( [arguments] )

        This function may be called directly from the LuaUnit table. It will
        create internally a LuaUnit runner and pass all arguments to it.

        Arguments and return value is the same as :lua:meth:`LuaUnit.runSuite()` 

        Example:

        .. code-block:: lua

            -- execute tests matching the 'withXY' pattern
            os.exit(lu.LuaUnit.run('--pattern', 'withXY'))



    .. lua:method:: runSuiteByInstances( listOfNameAndInstances  )

        This function runs test without performing the global test collection process on the global namespace, the test
        are explicitely provided as argument, along with their names.

        Before execution, the function will parse the script command-line, like :lua:meth:`LuaUnit.runSuite()`.

        Input is provided as a list of *{ name, test_instance }* where *test_instance* can either be a function or a table containing 
        test functions starting with the prefix *test*.


        **Example of using runSuiteByInstances**

        .. code-block:: lua

            lu = require('luaunit')

            runner = lu.LuaUnit.new()
            os.exit(runner.runSuiteByInstances( {'mySpecialTest1', mySpecialTest1}, {'mySpecialTest2', mySpecialTest2} } )


Skipping and ending test 
==========================

LuaUnit allows to force test ending in several ways.

Test skipping
-----------------

.. lua:function:: skip( message )

    Stops the ongoing test and mark it as skipped with the given message. This can be used
    to deactivate a given test.


.. lua:function:: skipIf( condition, message )

    If the condition *condition* evaluates to *true*, stops the ongoing test and mark it as skipped with the given message.
    Else, continue the test execution normally.

    The expected usage is to call the function at the beginning of the test to
    verify if the conditions are met for executing such tests.


.. lua:function:: runOnlyIf( condition, message )

    If condition evaluates to *false*, stops the ongoing test and mark it as skipped with the 
    given message. This is the opposite behavior of :lua:func:`skipIf()` .

    The expected usage is to call the function at the beginning of the test to
    verify if the conditions are met for executing such tests.


Number of skipped tests, if any, are reported at the end of the execution.


Force test failing
------------------

.. lua:function:: fail( message )

    Stops the ongoing test and mark it as failed with the given message.


.. lua:function:: failIf( condition, message )

    If the condition *condition* evaluates to *true*, stops the ongoing test and mark it as failed with the given message.
    Else, continue the test execution normally.


Force test success
-------------------

.. lua:function:: success()

    Stops the ongoing test and mark it as successful.

.. lua:function:: successIf( condition )

    If the condition *condition* evaluates to *true*, stops the ongoing test and mark it as successful.
    Else, continue the test execution normally.



.. _output-formats-details:

Output formats details
=======================


To demonstrate the different output formats, we will take the example of the :ref:`getting-started` section and add the following two failing cases:

.. code-block:: lua

    TestWithFailures = {}
        -- two failing tests
        
        function TestWithFailures:testFail1()
            local a="toto"
            local b="titi"
            lu.assertEquals( a, b ) --oops, two values are not equal
        end

        function TestWithFailures:testFail2()
            local a=1
            local b='toto'
            local c = a + b --oops, can not add string and numbers
            return c
        end


Text format
------------

By default, LuaUnit uses the output format TEXT, with minimum verbosity::

    $ lua my_test_suite.lua
    .......FE
    Failed tests:
    -------------
    1) TestWithFailures.testFail1
    doc\my_test_suite_with_failures.lua:79: expected: "titi"
    actual: "toto"
    stack traceback:
            doc\my_test_suite_with_failures.lua:79: in function 'TestWithFailures.testFail1'

    2) TestWithFailures.testFail2
    doc\my_test_suite_with_failures.lua:85: attempt to perform arithmetic on local 'b' (a string value)
    stack traceback:
            [C]: in function 'xpcall'

    Ran 9 tests in 0.001 seconds, 7 successes, 1 failure, 1 error

This format is heavily inspired by python unit-test library. One character is printed
for every test executed, a dot for a successful test, a **F** for a test with failure and
a **E** for a test with an error.

At the end of the test suite execution, the details of the failures or errors are given, with an
informative message and a full stack trace.

The last line sums up the number of test executed, successful, failed, in error and not selected if any.
When all tests are successful, a line with just OK is added::

    $ lua doc\my_test_suite.lua
    .......
    Ran 7 tests in 0.002 seconds, 7 successes, 0 failures
    OK


The text format is also available as a more verbose version, by adding the ``--verbose`` flag::

    $ lua doc\my_test_suite_with_failures.lua --verbose
    Started on 02/20/17 21:47:21
        TestAdd.testAddError ... Ok
        TestAdd.testAddPositive ... Ok
        TestAdd.testAddZero ... Ok
        TestAdd.testAdder ... Ok
        TestDiv.testDivError ... Ok
        TestDiv.testDivPositive ... Ok
        TestDiv.testDivZero ... Ok
        TestWithFailures.testFail1 ... FAIL
    doc\my_test_suite_with_failures.lua:79: expected: "titi"
    actual: "toto"
        TestWithFailures.testFail2 ... ERROR
    doc\my_test_suite_with_failures.lua:85: attempt to perform arithmetic on local 'b' (a string value)
    =========================================================
    Failed tests:
    -------------
    1) TestWithFailures.testFail1
    doc\my_test_suite_with_failures.lua:79: expected: "titi"
    actual: "toto"
    stack traceback:
            doc\my_test_suite_with_failures.lua:79: in function 'TestWithFailures.testFail1'

    2) TestWithFailures.testFail2
    doc\my_test_suite_with_failures.lua:85: attempt to perform arithmetic on local 'b' (a string value)
    stack traceback:
            [C]: in function 'xpcall'

    Ran 9 tests in 0.008 seconds, 7 successes, 1 failure, 1 error

In this format, you get:

* a first line with date-time at which the test was started
* one line per test executed
* the test line is ended by **Ok**, **FAIL**, or **ERROR** in case the test is not successful
* a summary of the failed tests with all details, like in the compact version.

This format is usually interesting if some tests print debug output, to match the output to the test.

JUNIT format
------------

The Junit XML format was introduced by the `Java testing framework JUnit`_ and has been then used by many continuous
integration platform as an interoperability format between test suites and the platform.

.. _Java testing framework JUnit: http://junit.org/junit4/ 

To output in the JUnit XML format, you use the format junit with ``--output junit`` and specify the XML filename with ``--name <filename>`` . On
the standard output, LuaUnit will print information about the test progress in a simple format.

Let's see with a simple example::

    $ lua my_test_suite_with_failures.lua -o junit -n toto.xml
    # XML output to toto.xml
    # Started on 02/24/17 09:54:59
    # Starting class: TestAdd
    # Starting test: TestAdd.testAddError
    # Starting test: TestAdd.testAddPositive
    # Starting test: TestAdd.testAddZero
    # Starting test: TestAdd.testAdder
    # Starting class: TestDiv
    # Starting test: TestDiv.testDivError
    # Starting test: TestDiv.testDivPositive
    # Starting test: TestDiv.testDivZero
    # Starting class: TestWithFailures
    # Starting test: TestWithFailures.testFail1
    # Failure: doc/my_test_suite_with_failures.lua:79: expected: "titi"
    # actual: "toto"
    # Starting test: TestWithFailures.testFail2
    # Error: doc/my_test_suite_with_failures.lua:85: attempt to perform arithmetic on local 'b' (a string value)
    # Ran 9 tests in 0.007 seconds, 7 successes, 1 failure, 1 error

On the standard output, you will see the date-time, the name of the XML file, one line for each test started, a summary 
of the failure or errors when they occurs and the usual one line summary of the test execution: number of tests run, successful, failed,
in error and number of non selected tests if any.

The XML file generated by this execution is the following::

    <?xml version="1.0" encoding="UTF-8" ?>
    <testsuites>
        <testsuite name="LuaUnit" id="00001" package="" hostname="localhost" tests="9" timestamp="2017-02-24T09:54:59" time="0.007" errors="1" failures="1">
            <properties>
                <property name="Lua Version" value="Lua 5.2"/>
                <property name="LuaUnit Version" value="3.2"/>
            </properties>
            <testcase classname="TestAdd" name="TestAdd.testAddError" time="0.001">
            </testcase>
            <testcase classname="TestAdd" name="TestAdd.testAddPositive" time="0.001">
            </testcase>
            <testcase classname="TestAdd" name="TestAdd.testAddZero" time="0.000">
            </testcase>
            <testcase classname="TestAdd" name="TestAdd.testAdder" time="0.000">
            </testcase>
            <testcase classname="TestDiv" name="TestDiv.testDivError" time="0.000">
            </testcase>
            <testcase classname="TestDiv" name="TestDiv.testDivPositive" time="0.000">
            </testcase>
            <testcase classname="TestDiv" name="TestDiv.testDivZero" time="0.001">
            </testcase>
            <testcase classname="TestWithFailures" name="TestWithFailures.testFail1" time="0.000">
                <failure type="doc/my_test_suite_with_failures.lua:79: expected: &quot;titi&quot;
    actual: &quot;toto&quot;">
                    <![CDATA[stack traceback:
            doc/my_test_suite_with_failures.lua:79: in function 'TestWithFailures.testFail1']]></failure>
            </testcase>
            <testcase classname="TestWithFailures" name="TestWithFailures.testFail2" time="0.000">
                <error type="doc/my_test_suite_with_failures.lua:85: attempt to perform arithmetic on local &apos;b&apos; (a string value)">
                    <![CDATA[stack traceback:
            [C]: in function 'xpcall']]></error>
            </testcase>
        <system-out/>
        <system-err/>
        </testsuite>
    </testsuites>

As you can see, the XML file is quite rich in terms of information. The verbosity level has no effect on junit output, all verbosity give the same output.

Slight inconsistencies exist in the exact XML format in the different continuous integration suites. LuaUnit provides a compatible output which
is validated against `Jenkins/Hudson schema`_ . If you ever find an problem in the XML formats, please report a bug to us, more testing is always welcome.

.. _Jenkins/Hudson schema: https://github.com/bluebird75/luaunit/blob/LUAUNIT_V3_2_1/junitxml/junit-jenkins.xsd  

TAP format
----------

The `TAP format`_ for test results has been around since 1988. LuaUnit produces TAP reports compatible with version 12 of
the specification.

.. _`TAP format`: https://testanything.org/

Example with minimal verbosiy::

    $ lua my_test_suite_with_failures.lua -o tap --quiet
    1..9
    # Started on 02/24/17 22:09:31
    # Starting class: TestAdd
    ok     1        TestAdd.testAddError
    ok     2        TestAdd.testAddPositive
    ok     3        TestAdd.testAddZero
    ok     4        TestAdd.testAdder
    # Starting class: TestDiv
    ok     5        TestDiv.testDivError
    ok     6        TestDiv.testDivPositive
    ok     7        TestDiv.testDivZero
    # Starting class: TestWithFailures
    not ok 8        TestWithFailures.testFail1
    not ok 9        TestWithFailures.testFail2
    # Ran 9 tests in 0.003 seconds, 7 successes, 1 failure, 1 error

With minimal verbosity, you have one line for each test run, with the status of the test, and one comment line
when starting the test suite, when starting a new class or when finishing the test.


Example with default verbosiy::

    $ lua my_test_suite_with_failures.lua -o tap
    1..9
    # Started on 02/24/17 22:09:31
    # Starting class: TestAdd
    ok     1        TestAdd.testAddError
    ok     2        TestAdd.testAddPositive
    ok     3        TestAdd.testAddZero
    ok     4        TestAdd.testAdder
    # Starting class: TestDiv
    ok     5        TestDiv.testDivError
    ok     6        TestDiv.testDivPositive
    ok     7        TestDiv.testDivZero
    # Starting class: TestWithFailures
    not ok 8        TestWithFailures.testFail1
        doc/my_test_suite_with_failures.lua:79: expected: "titi"
        actual: "toto"
    not ok 9        TestWithFailures.testFail2
        doc/my_test_suite_with_failures.lua:85: attempt to perform arithmetic on local 'b' (a string value)
    # Ran 9 tests in 0.005 seconds, 7 successes, 1 failure, 1 error

In the default mode, the failure or error message is displayed in the failing test diagnostic part.

Example with full verbosiy::

    $ lua my_test_suite_with_failures.lua -o tap --verbose
    1..9
    # Started on 02/24/17 22:09:31
    # Starting class: TestAdd
    ok     1        TestAdd.testAddError
    ok     2        TestAdd.testAddPositive
    ok     3        TestAdd.testAddZero
    ok     4        TestAdd.testAdder
    # Starting class: TestDiv
    ok     5        TestDiv.testDivError
    ok     6        TestDiv.testDivPositive
    ok     7        TestDiv.testDivZero
    # Starting class: TestWithFailures
    not ok 8        TestWithFailures.testFail1
        doc/my_test_suite_with_failures.lua:79: expected: "titi"
        actual: "toto"
        stack traceback:
            doc/my_test_suite_with_failures.lua:79: in function 'TestWithFailures.testFail1'
    not ok 9        TestWithFailures.testFail2
        doc/my_test_suite_with_failures.lua:85: attempt to perform arithmetic on local 'b' (a string value)
        stack traceback:
            [C]: in function 'xpcall'
    # Ran 9 tests in 0.007 seconds, 7 successes, 1 failure, 1 error

With maximum verbosity, the stack trace is also displayed in the test diagnostic.

NIL format
----------

With the nil format output, absolutely nothing is displayed while running the tests. Only the
exit code of the command can tell whether the test was successful or not::

    $ lua my_test_suite_with_failures.lua -o nil --verbose
    $

This mode is used by LuaUnit for its internal validation.



Test collection and execution process
======================================

Test collection
-------------------

The test collection and execution process is the following:

* If a list of tests is specified on the command-line or as argument to the *runSuite()* or *runSuiteByInstances()*, this 
  the considered list of tests to run.
* If no list of tests is specified, the global namespace *_G* is searched for names starting by *test* or *Test*. All
  such names are put into the list of tests to run (provided they reference either a function or a table).
* All tables are then scanned for table functions starting with *test* or *Test*, which are then added to the list of tests to run
* From the list of tests to run, include and exclude patterns are applied
* If shuffling is activated, the list is randomized. Else, it is sorted in alphabetical order.

This constitutes the final list of tests to run.

Test execution
-------------------

Each test function is run in a protected call. If any luaunit assertion fails (assertEquals, ...), the test is considered as a failure. If
an error is generated during the test execution, the test is marked as in error. Both errors and failures are reported at the end of the execution.

When executing a table containing tests, the following methods are also considered:

* *setUp()* is called prior to each test execution. Any failure or error during *setUp()* will prevent the test from being executed and will
  be reported in the test suite.
* *tearDown()* is called after each test, even if the *setUp()* or the test failed. Any failure or error during *tearDown()* will be reported
  in the test suite.


Assertions functions
=====================
We will now list all assertion functions. For every functions, the failure
message tries to be as informative as possible, by displaying the expectation and value that caused the failure. It
relies on the :lua:func:`prettystr` for printing nicely formatted values.

All function accept an optional extra message which if provided, is printed along with the failure message.

.. Note:: see :ref:`table-printing` for more information on how LuaUnit prints tables.

.. _equality-assertions:

Equality assertions
----------------------
All equality assertions functions take two arguments, in the order 
*actual value* then *expected value*. Some people are more familiar
with the order *expected value* then *actual value*. It is possible to configure
LuaUnit to use the opposite order for all equality assertions, by setting up a module
variable:

.. code-block:: lua

    lu.ORDER_ACTUAL_EXPECTED=false

The order only matters for the message that is displayed in case of failures. It does
not influence the test itself.


.. lua:function:: assertEquals(actual, expected [, extra_msg] )

    **Alias**: *assert_equals()*

    Assert that two values are equal. This is the most used function for assertion within LuaUnit.
    The values being compared may be integers, floats, strings, tables, functions or a combination of 
    those. If provided, *extra_msg* is a string which will be printed along with the failure message.

    When comparing floating point numbers, it is better to use :lua:func:`assertAlmostEquals` which supports a margin
    for the equality verification.

    For tables, the comparison supports nested tables and cyclic structures. To be equal, two tables must
    have the same keys and the value associated with a key must compare equal with assertEquals() (using a recursive
    algorithm).

    When displaying the difference between two tables used as lists, LuaUnit performs an analysis of the list content
    to pinpoint the place where the list actually differs. See the below example:

.. code-block::

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



.. Note:: see :ref:`comparing-table-keys-table` for information on comparison of tables containing keys of type table.

    LuaUnit provides other table-related assertions, see :ref:`assert-table` .


.. lua:function:: assertNotEquals(actual, expected [, extra_msg])

    **Alias**: *assert_not_equals()*

    Assert that two values are different. The assertion
    fails if the two values are identical. It behaves exactly like :lua:func:`assertEquals` but checks
    for the opposite condition.

    If provided, *extra_msg* is a string which will be printed along with the failure message.

Value assertions
----------------------

LuaUnit contains several flavours of true/false assertions, to be used in different contexts.
Usually, when asserting for *true* or *false*, you want strict assertions (*nil* should not 
assert to *false*); *assertTrue()* and *assertFalse()* are the functions for this purpose. In some cases though,
you want Lua coercion rules to apply (e.g. value *1* or string *"hello"* yields *true*) and the right functions to use
are *assertEvalToTrue()* and *assertEvalToFalse()*. Finally, you have the *assertNotTrue()* and *assertNotFalse()* to verify
that a value is anything but the boolean *true* or *false*.

The below table sums it up:

    **True assertion family**

============  ============  ===================  ================
Input Value   assertTrue()  assertEvalToTrue()   assertNotTrue()
============  ============  ===================  ================
*true*        OK            OK                   OK
*false*       Fail          Fail                 Fail
*nil*         Fail          Fail                 OK
*0*           Fail          OK                   OK
*1*           Fail          OK                   OK
*"hello"*     Fail          OK                   OK
============  ============  ===================  ================

    **False assertion family**

============  ================  =============  ===================
Input Value   assertNotFalse()  assertFalse()  assertEvalToFalse()
============  ================  =============  ===================
*true*        Fail              Fail           Fail
*false*       OK                OK             OK
*nil*         Fail              OK             OK
*0*           Fail              Fail           Fail
*1*           Fail              Fail           Fail
*"hello"*     Fail              Fail           Fail
============  ================  =============  ===================

.. lua:function:: assertEvalToTrue(value [, extra_msg])

    **Alias**: *assert_eval_to_true()*

    Assert that a given value evals to ``true``. Lua coercion rules are applied
    so that values like ``0``, ``""``, ``1.17`` **succeed** in this assertion. If provided, 
    extra_msg is a string which will be printed along with the failure message.

    See :lua:func:`assertTrue` for a strict assertion to boolean ``true``.

.. lua:function:: assertEvalToFalse(value [, extra_msg])

    **Alias**: *assert_eval_to_false()*

    Assert that a given value eval to ``false``. Lua coercion rules are applied
    so that ``nil`` and ``false``  **succeed** in this assertion. If provided, extra_msg 
    is a string which will be printed along with the failure message.

    See :lua:func:`assertFalse` for a strict assertion to boolean ``false``.
    
.. lua:function:: assertTrue(value [, extra_msg])

    **Alias**: *assert_true()*

    Assert that a given value is strictly ``true``. Lua coercion rules do not apply
    so that values like ``0``, ``""``, ``1.17`` **fail** in this assertion. If provided, 
    extra_msg is a string which will be printed along with the failure message.

    See :lua:func:`assertEvalToTrue` for an assertion to ``true`` where Lua coercion rules apply.
    
.. lua:function:: assertFalse(value [, extra_msg])

    **Alias**: *assert_false()*

    Assert that a given value is strictly ``false``. Lua coercion rules do not apply
    so that ``nil`` **fails** in this assertion. If provided, *extra_msg* is a string 
    which will be printed along with the failure message.

    See :lua:func:`assertEvalToFalse` for an assertion to ``false`` where Lua coertion fules apply.
    
.. lua:function:: assertNil(value [, extra_msg])

    **Aliases**: *assert_nil()*, *assertIsNil()*, *assert_is_nil()*

    Assert that a given value is *nil* . If provided, *extra_msg* is 
    a string which will be printed along with the failure message.
    
.. lua:function:: assertNotNil(value [, extra_msg])

    **Aliases**: *assert_not_nil()*, *assertNotIsNil()*, *assert_not_is_nil()*

    Assert that a given value is not *nil* . Lua coercion rules are applied
    so that values like ``0``, ``""``, ``false`` all validate the assertion.
    If provided, *extra_msg* is a string which will be printed along with the failure message.

.. lua:function:: assertIs(actual, expected [, extra_msg])

    **Alias**: *assert_is()*

    Assert that two variables are identical. For string, numbers, boolean and for nil, 
    this gives the same result as :lua:func:`assertEquals` . For the other types, identity
    means that the two variables refer to the same object. 
    If provided, *extra_msg* is a string which will be printed along with the failure message.

    **Example :**

    .. code-block:: lua

            s1='toto'
            s2='to'..'to'
            t1={1,2}
            t2={1,2}
            v1=nil
            v2=false

            lu.assertIs(s1,s1) -- ok
            lu.assertIs(s1,s2) -- ok
            lu.assertIs(t1,t1) -- ok
            lu.assertIs(t1,t2) -- fail
            lu.assertIs(v1,v2) -- fail
    
.. lua:function:: assertNotIs(actual, expected [, extra_msg])

    **Alias**: *assert_not_is()*

    Assert that two variables are not identical, in the sense that they do not
    refer to the same value. If provided, *extra_msg* is a string which will be printed along with the failure message.

    See :lua:func:`assertIs` for more details.
    

String assertions
--------------------------

Assertions related to string and patterns.

.. lua:function:: assertStrContains( str, sub [, isPattern [, extra_msg ]] )

    **Alias**: *assert_str_contains()*

    Assert that the string *str* contains the substring or pattern *sub*. 
    If provided, *extra_msg* is a string which will be printed along with the failure message.

    By default, substring is searched in the string. If *isPattern*
    is provided and is true, *sub* is treated as a pattern which
    is searched inside the string *str* .
    

.. lua:function:: assertStrIContains( str, sub [, extra_msg] )

    **Alias**: *assert_str_icontains()*

    Assert that the string *str* contains the given substring *sub*, irrespective of the case. 
    If provided, *extra_msg* is a string which will be printed along with the failure message.

    Note that unlike :lua:func:`assertStrcontains`, you can not search for a pattern.



.. lua:function:: assertNotStrContains( str, sub, [isPattern [, extra_msg]] )

    **Alias**: *assert_not_str_contains()*

    Assert that the string *str* does not contain the substring or pattern *sub*.
    If provided, *extra_msg* is a string which will be printed along with the failure message.

    By default, the substring is searched in the string. If *isPattern*
    is provided and is true, *sub* is treated as a pattern which
    is searched inside the string *str* .
    

.. lua:function:: assertNotStrIContains( str, sub [, extra_msg] )

    **Alias**: *assert_not_str_icontains()*

    Assert that the string *str* does not contain the substring *sub*, irrespective of the case. 
    If provided, *extra_msg* is a string which will be printed along with the failure message.

    Note that unlike :lua:func:`assertNotStrcontains`, you can not search for a pattern.


.. lua:function:: assertStrMatches( str, pattern [, start [, final [, extra_msg ]]]  )

    **Alias**: *assert_str_matches()*

    Assert that the string *str* matches the full pattern *pattern*.

    If *start* and *final* are not provided or are *nil*, the pattern must match the full string, from start to end. The
    function allows to specify the expected start and end position of the pattern in the string. If provided, 
    *extra_msg* is a string which will be printed along with the failure message.

.. _error-assertions:    

Error assertions
--------------------------
Error related assertions, to verify error generation and error messages.

.. lua:function:: assertError( func, ...)

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
    
.. lua:function:: assertErrorMsgEquals( expectedMsg, func, ... )

    **Alias**: *assert_error_msg_equals()*

    Assert that calling function *func* will generate exactly the given error message. If the
    function does not yield an error, or if the error message is not identical, the assertion fails.

    Be careful when using this function that error messages usually contain the file name and
    line number information of where the error was generated. This is usually inconvenient so we have
    introduced the :lua:func:`assertErrorMsgContentEquals` . Be sure to check it.


.. lua:function:: assertErrorMsgContentEquals( expectedMsg, func, ... )

    **Alias**: *assert_error_msg_content_equals()*

    Assert that calling function *func* will generate exactly the given error message, excluding the
    file and line information. File and line information may change as your programs evolve so we
    find this version more convenient than :lua:func:`assertErrorMsgEquals` .



.. lua:function:: assertErrorMsgContains( partialMsg, func, ... )

    **Alias**: *assert_error_msg_contains()*

    Assert that calling function *func* will generate an error message containing *partialMsg* . If the
    function does not yield an error, or if the expected message is not contained in the error message, the 
    assertion fails.


    
.. lua:function:: assertErrorMsgMatches( expectedPattern, func, ... )

    **Alias**: *assert_error_msg_matches()*

    Assert that calling function *func* will generate an error message matching *expectedPattern* . If the
    function does not yield an error, or if the error message does not match the provided patternm the
    assertion fails.

    Note that matching is done from the start to the end of the error message. Be sure to escape magic all magic
    characters with ``%`` (like ``-+.?*``) .

.. _type-assertions:    

Type assertions
--------------------------

The following functions all perform type checking on their argument. If the
received value is not of the right type, the failure message will contain
the expected type, the received type and the received value to help you
identify better the problem.

.. lua:function:: assertIsNumber(value [, extra_msg])

    **Aliases**: *assertNumber()*, *assert_is_number()*, *assert_number()*

    Assert that the argument is a number (integer or float).
    If provided, *extra_msg* is a string which will be printed along with the failure message.
    
.. lua:function:: assertIsString(value [, extra_msg])

    **Aliases**: *assertString()*, *assert_is_string()*, *assert_string()*

    Assert that the argument is a string.
    If provided, *extra_msg* is a string which will be printed along with the failure message.
    
.. lua:function:: assertIsTable(value [, extra_msg])

    **Aliases**: *assertTable()*, *assert_is_table()*, *assert_table()*

    Assert that the argument is a table.
    If provided, *extra_msg* is a string which will be printed along with the failure message.
    
.. lua:function:: assertIsBoolean(value [, extra_msg])

    **Aliases**: *assertBoolean()*, *assert_is_boolean()*, *assert_boolean()*

    Assert that the argument is a boolean.
    If provided, *extra_msg* is a string which will be printed along with the failure message.
    
.. lua:function:: assertIsNil(value [, extra_msg])

    **Aliases**: *assertNil()*, *assert_is_nil()*, *assert_nil()*

    Assert that the argument is nil.
    If provided, *extra_msg* is a string which will be printed along with the failure message.
    
.. lua:function:: assertIsFunction(value [, extra_msg])

    **Aliases**: *assertFunction()*, *assert_is_function()*, *assert_function()*

    Assert that the argument is a function.
    If provided, *extra_msg* is a string which will be printed along with the failure message.
    
.. lua:function:: assertIsUserdata(value [, extra_msg])

    **Aliases**: *assertUserdata()*, *assert_is_userdata()*, *assert_userdata()*

    Assert that the argument is a userdata.
    If provided, *extra_msg* is a string which will be printed along with the failure message.
    
.. lua:function:: assertIsCoroutine(value [, extra_msg])

    **Aliases**: *assertCoroutine()*, *assert_is_coroutine()*, *assert_coroutine()*

    Assert that the argument is a coroutine (an object with type *thread* ).
    If provided, *extra_msg* is a string which will be printed along with the failure message.
    
.. lua:function:: assertIsThread(value [, extra_msg])

    **Aliases**: *assertIsThread()*, *assertThread()*, *assert_is_thread()*, *assert_thread()*

    Same function as :lua:func:`assertIsCoroutine` . Since Lua coroutines have the type thread, it's not
    clear which name is the clearer, so we provide syntax for both names.
    If provided, *extra_msg* is a string which will be printed along with the failure message.


.. _assert-table:

Table assertions
--------------------------

.. lua:function:: assertItemsEquals(actual, expected [, extra_msg])

    **Alias**: *assert_items_equals()*

    Assert that two tables contain the same items, irrespective of their keys.
    If provided, *extra_msg* is a string which will be printed along with the failure message.

    This function is practical for example if you want to compare two lists but
    where items are not in the same order:

.. code-block:: lua

        lu.assertItemsEquals( {1,2,3}, {3,2,1} ) -- assertion succeeds

..

    The comparison is not recursive on the items: if any of the items are tables,
    they are compared using table equality (like as in :lua:func:`assertEquals` ), where
    the key matters.


.. code-block:: lua

        lu.assertItemsEquals( {1,{2,3},4}, {4,{3,2,},1} ) -- assertion fails because {2,3} ~= {3,2}



.. lua:function:: assertTableContains(table, element [, extra_msg])

    **Alias**: *assert_table_contains()*

    Assert that the table contains at least one key with value `element`. Element
    may be of any type (including table), the recursive equality algorithm of assertEquals()
    is used for verifying the presence of the element.
    If provided, *extra_msg* is a string which will be printed along with the failure message.

.. code-block:: lua

        lu.assertTableContains( {'a', 'b', 'c', 'd'}, 'b' ) -- assertion succeeds
        lu.assertTableContains( {1, 2, 3, {4} }, {4} } -- assertion succeeds


.. lua:function:: assertNotTableContains(table, element [, extra_msg])

    **Alias**: *assert_not_table_contains()*

    Negative version of :lua:func:`assertTableContains` .

    Assert that the table contains no element with value `element`. Element
    may be of any type (including table), the recursive equality algorithm of assertEquals()
    is used for verifying the presence of the element.
    If provided, *extra_msg* is a string which will be printed along with the failure message.

.. code-block:: lua

        lu.assertNotTableContains( {'a', 'b', 'c', 'd'}, 'e' ) -- assertion succeeds
        lu.assertNotTableContains( {1, 2, 3, {4} }, {5} } -- assertion succeeds




Scientific computing and LuaUnit
--------------------------------

LuaUnit is used by the CERN for the MAD-NG program, the forefront of computational physics in the field of particle accelerator design and simulation (See MAD_). Thank to the feedback of a scientific computing developer, LuaUnit has been enhanced with some facilities for scientific applications (see all assertions functions below).

.. _MAD: http://mad.web.cern.ch/mad/

The floating point library used by Lua is the one provided by the C compiler which built Lua. It is usually compliant with IEEE-754_ . As such, 
it can yields results such as *plus infinity*, *minus infinity* or *Not a Number* (NaN). The precision of any calculation performed in Lua is 
related to the smallest representable floating point value (typically called *EPS*): 2^-52 for 64 bits floats (type double in the C language) and 2^-23 for 32 bits float 
(type float in C). 

.. _IEEE-754: https://en.wikipedia.org/wiki/IEEE_754 

.. Note :: Lua may be compiled with numbers represented either as 32 bits floats or 64 bits double (as defined by the macro LUA_FLOAT_TYPE in luaconf.h ). LuaUnit has been validated in both these configurations and in particuluar, the epsilon value *EPS* is adjusted accordingly.

For more information about performing calculations on computers, please read the reference paper `What Every Computer Scientist Should Know About Floating-Point Arithmetic`_

.. _What Every Computer Scientist Should Know About Floating-Point Arithmetic: https://docs.oracle.com/cd/E19957-01/806-3568/ncg_goldberg.html 

If your calculation shall be portable to multiple OS or compilers, you may get different calculation errors depending on the OS/compiler. It is therefore important to verify them on every target.


.. _MinusZero: 

.. Note on minus zero:: 
    If you need to deal with value *minus zero*, be very careful because Lua versions are inconsistent on how they treat the syntax *-0* : it creates either
    a *plus zero* or a *minus zero* . Multiplying or dividing *0* by *-1* also yields inconsistent results. The reliable way to create the *-0* 
    value is : minusZero = -1 / (1/0)


.. _EPS:

EPS *constant*
-----------------

The machine epsilon, to be used with :lua:func:`assertAlmostEquals` .

This is either:

* 2^-52 or ~2.22E-16 (with lua number defined as double)
* 2^-23 or ~1.19E-07 (with lua number defined as float)


.. lua:function:: assertNan( value  [, extra_msg])

    **Alias**: *assert_nan()*

    Assert that a given number is a *NaN* (Not a Number), according to the definition of IEEE-754_ .
    If provided, *extra_msg* is a string which will be printed along with the failure message.


.. lua:function:: assertNotNan( value  [, extra_msg])

    **Alias**: *assert_not_nan()*

    Assert that a given number is NOT a *NaN* (Not a Number), according to the definition of IEEE-754_ .
    If provided, *extra_msg* is a string which will be printed along with the failure message.


.. lua:function:: assertPlusInf( value  [, extra_msg])

    **Alias**: *assert_plus_inf()*

    Assert that a given number is *plus infinity*, according to the definition of IEEE-754_ .
    If provided, *extra_msg* is a string which will be printed along with the failure message.


.. lua:function:: assertMinusInf( value  [, extra_msg])

    **Alias**: *assert_minus_inf()*

    Assert that a given number is *minus infinity*, according to the definition of IEEE-754_ .
    If provided, *extra_msg* is a string which will be printed along with the failure message.


.. lua:function:: assertInf( value  [, extra_msg])

    **Alias**: *assert_inf()*

    Assert that a given number is *infinity* (either positive or negative), according to the definition of IEEE-754_ .
    If provided, *extra_msg* is a string which will be printed along with the failure message.


.. lua:function:: assertNotPlusInf( value  [, extra_msg])

    **Alias**: *assert_not_plus_inf()*

    Assert that a given number is NOT *plus infinity*, according to the definition of IEEE-754_ .
    If provided, *extra_msg* is a string which will be printed along with the failure message.


.. lua:function:: assertNotMinusInf( value  [, extra_msg])

    **Alias**: *assert_not_minus_inf()*

    Assert that a given number is NOT *minus infinity*, according to the definition of IEEE-754_ .
    If provided, *extra_msg* is a string which will be printed along with the failure message.


.. lua:function:: assertNotInf( value  [, extra_msg])

    **Alias**: *assert_not_inf()*

    Assert that a given number is neither *infinity* nor *minus infinity*, according to the definition of IEEE-754_ .
    If provided, *extra_msg* is a string which will be printed along with the failure message.


.. lua:function:: assertPlusZero( value  [, extra_msg])

    **Alias**: *assert_plus_zero()*

    Assert that a given number is *+0*, according to the definition of IEEE-754_ . The
    verification is done by dividing by the provided number and verifying that it yields
    *infinity* . If provided, *extra_msg* is a string which will be printed along with the failure message.

    Be careful when dealing with *+0* and *-0*, see note above.


.. lua:function:: assertMinusZero( value  [, extra_msg])

    **Alias**: *assert_minus_zero()*

    Assert that a given number is *-0*, according to the definition of IEEE-754_ . The
    verification is done by dividing by the provided number and verifying that it yields
    *minus infinity* . If provided, *extra_msg* is a string which will be printed along with the failure message.

    Be careful when dealing with *+0* and *-0*, see MinusZero_


.. lua:function:: assertNotPlusZero( value  [, extra_msg])

    **Alias**: *assert_not_plus_zero()*

    Assert that a given number is NOT *+0*, according to the definition of IEEE-754_ .
    If provided, *extra_msg* is a string which will be printed along with the failure message.

    Be careful when dealing with *+0* and *-0*, see MinusZero_


.. lua:function:: assertNotMinusZero( value  [, extra_msg])

    **Alias**: *assert_not_minus_zero()*

    Assert that a given number is NOT *-0*, according to the definition of IEEE-754_ .
    If provided, *extra_msg* is a string which will be printed along with the failure message.

    Be careful when dealing with *+0* and *-0*, see MinusZero_


.. lua:function:: assertAlmostEquals( actual, expected [, margin=EPS [, extra_msg]] )

    **Alias**: *assert_almost_equals()*

    Assert that two floating point numbers or tables are equal by the defined margin. 
    If margin is not provided, the machine epsilon *EPS* is used.
    If provided, *extra_msg* is a string which will be printed along with the failure message.

    The function accepts either floating point numbers or tables. Complex structures with
    nested tables are supported. Comparing tables with assertAlmostEquals works just like :lua:func:`assertEquals`
    with the difference that values are compared with a margin instead of with direct equality.

    Be careful that depending on the calculation, it might make more sense to measure
    the absolute error or the relative error (see below):


.. lua:function:: assertNotAlmostEquals( actual, expected [, margin=EPS [, extra_msg]] )

    **Alias**: *assert_not_almost_equals()*

    Assert that two floating point numbers are not equal by the defined margin.
    If margin is not provided, the machine epsilon *EPS* is used.
    If provided, *extra_msg* is a string which will be printed along with the failure message.

    Be careful that depending on the calculation, it might make more sense to measure
    the absolute error or the relative error (see below).


    **Example of absolute versus relative error**
        
    .. code-block:: lua

            -- convert pi/6 radian to 30 degree 
            pi_div_6_deg_calculated = math.deg(math.pi/6)
            pi_div_6_deg_expected = 30

            -- convert pi/3 radian to 60 degree 
            pi_div_3_deg_calculated = math.deg(math.pi/3)
            pi_div_3_deg_expected = 60

            -- check absolute error: it is not constant
            print( (pi_div_6_deg_expected - pi_div_6_deg_calculated) / lu.EPS ) -- prints: 16
            print( (pi_div_3_deg_expected - pi_div_3_deg_calculated) / lu.EPS ) -- prints: 3

            -- The difference between expected value and calculated value is bigger than the machine epsilon, so 
            -- it will fail an assertAlmostEquals with default margin. You could supply a bigger margin, but it is not a 
            -- good solution because the error is not constant and it will be bigger for some calculations than for others.

            -- A better approach is to use relative error:
            print( ( (pi_div_6_deg_expected - pi_div_6_deg_calculated) / pi_div_6_deg_expected) / lu.EPS ) -- prints: 0.53333
            print( ( (pi_div_3_deg_expected - pi_div_3_deg_calculated) / pi_div_3_deg_expected) / lu.EPS ) -- prints: 0.53333

            -- By dividing the error by the expected value, we get a constant error for both calculations, which is less than
            -- the machine epsilon. This is more reliable and assertAlmostEquals() will succeed with the default margin.

            -- relative error is constant. Assertion can take the form of:
            assertAlmostEquals( (pi_div_6_deg_expected - pi_div_6_deg_calculated) / pi_div_6_deg_expected, lu.EPS )
            assertAlmostEquals( (pi_div_3_deg_expected - pi_div_3_deg_calculated) / pi_div_3_deg_expected, lu.EPS )

            -- or simply (relying on the default margin):
            assertAlmostEquals( (pi_div_6_deg_expected - pi_div_6_deg_calculated) / pi_div_6_deg_expected)
            assertAlmostEquals( (pi_div_3_deg_expected - pi_div_3_deg_calculated) / pi_div_3_deg_expected)


Pretty printing
----------------

.. lua:function:: prettystr( value )

    Converts *value* to a nicely formatted string, whatever the type of the value.
    It supports in particular tables, nested table and even recursive tables.

    You can use it in your code to replace calls to *tostring()* .

    **Example of prettystr()**
        
    .. code-block:: 

            > lu = require('luaunit')
            > t1 = {1,2,3}
            > t1['toto'] = 'titi'
            > t1.f = function () end
            > t1.fa = (1 == 0)
            > t1.tr = (1 == 1)
            > print( lu.prettystr(t1) )
            {1, 2, 3, f=function: 00635d68, fa=false, toto="titi", tr=true}


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
    lu = require('luaunit')

    TestToto = {} --class

        function TestToto:test1_withFailure()
            local a = 1
            lu.assertEquals( a , 1 )
            -- will fail
            lu.assertEquals( a , 2 )
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


Variables controlling LuaUnit behavior
=========================================

luaunit.ORDER_ACTUAL_EXPECTED
------------------------------

This boolean value defines the order of arguments in assertion functions.

For example, in the code `luaunit.assertEquals( a, b )` , LuaUnit will treat by default
`a` as a calculated value under test (actual value) and `b` as a reference value aginst which `a` is 
compared (expected value). This will show up in the error reported for the test:

.. code-block:: shell

    1) TestWithFailures.testFail1
    doc\my_test_suite_with_failures.lua:79: expected: "titi"
    actual: "toto"

If you prefer the opposite convention, i.e having the expected argument as first
and actual argument as second, set the *ORDER_ACTUAL_EXPECTED* to *false*.


luaunit.PRINT_TABLE_REF_IN_ERROR_MSG
------------------------------------------

This controls whether table references are always printed along with table or not. See :ref:`table-printing` for details. The
default is `false`.


.. _strip_extra_entries_in_stack_trace:

luaunit.STRIP_EXTRA_ENTRIES_IN_STACK_TRACE
------------------------------------------

This controls how many extra entries in a stack-trace are stripped. By default, LuaUnit hides all its internals
functions to show only user code in the error stack trace. However, if LuaUnit is used as part of another test
framework, and one wants to also hide this global test framework entries, you can increase the number here. The default
is *0* .


luaunit.VERSION
------------------------------------------

Current version of LuaUnit as a string.
