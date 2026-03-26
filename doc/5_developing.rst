
.. _developing-luaUnit:

Developing LuaUnit
******************

Development ecosystem
======================

LuaUnit is developed on `GitHub`_.

.. _GitHub: https://github.com/bluebird75/luaunit

Bugs or feature requests should be reported using `GitHub issues`_.

.. _GitHub issues: https://github.com/bluebird75/luaunit/issues

LuaUnit is released under the BSD license.

This documentation is available at `Read-the-docs`_.

.. _Read-the-docs: http://luaunit.readthedocs.org/en/latest/


Contributing
=============
You may contribute to LuaUnit by reporting bugs or wishes, or by contributing code directly with a pull request.

Some issues on GitHub are marked with label *enhancement*. Feel also free to pick up such tasks and implement them.

Changes should be proposed as *Pull Requests* on GitHub.

Thank to our continuous integration setup, all unit-tests and functional tests are run on Linux, Windows and MacOs, with all versions of Lua. So
any *Pull Request* will show immediately if anything is going unexpected.


Running unit-tests
-------------------
All proposed changes should pass all unit-tests and if needed, add more unit-tests to cover the bug or the new functionality. Usage is pretty simple:

.. code-block:: shell

    $ lua run_unit_tests.lua
    ................................................................................
    ...............................
    Ran 111 tests in 0.120 seconds
    OK


Running functional tests
----------------------------
Functional tests also exist to validate LuaUnit. Their management is slightly more complicated. 

The main goal of functional tests is to validate that LuaUnit output has not been altered. Since LuaUnit supports some standard compliant output (TAP, junitxml), this is very important (and it has been broken in the past).

Functional tests perform the following actions:

* Run the 2 suites: example_with_luaunit.lua, test_with_err_fail_pass.lua (with various options to have successe, failure and/or errors)
* Run every suite with all output format, all verbosity
* Validate the XML output with jenkins/hudson and junit schema
* Compare the results with the reference output ( archived in test/ref ), with some tricks to make the comparison possible :

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
    With SourceTree or SublimeMerge for example, in case of XML changes, I can select only the
    lines relevant to the change and avoid committing all the updates to test
    duration and test datestamp.



Typical failures for functional tests
---------------------------------------

Functional tests may start failing when:

1. Increasing LuaUnit version
2. Improving or breaking LuaUnit output

This a good place to start looking if you see failures occurring.


Using doit.py
--------------

The utility *doit.py* is a useful developer tool to repeat common developer commands.

**Running syntax check**

.. code-block:: shell

    doit.py luacheck

Run luacheck on the LuaUnit code.


**Running unit-tests**

.. code-block:: shell

    doit.py rununittests 

Use it to run all unit tests, on all installed versions of Lua on the sytem.


**Running all tests**

.. code-block:: shell

    doit.py runtests

Run luacheck then run unit-tests then run functional tests. Just like the continuous integration.

**Creating documentation**

.. code-block:: shell

    doit.py makedoc

Runs sphinx to generate the html documentation. You must have sphinx installed on your path.


**Preparing a release**

.. code-block:: shell

    doit.py buildrock

Create a rock file ready to be uploaded to luarocks, containing a clone of the current git, with documentation generated
README and LICENSE, tests, and everything else stripped out.


.. code-block:: shell

    doit.py packageit

Create a zip and tar.gz archive suitable to be uploaded to github. The archive is composed of a clone
of the current git content, stripped from everything not related to using luaunit (no CI files, no doit.lu, ...)
but with full documentation generated.


Process of releasing a new version of LuaUnit
=============================================

The steps are the following:

* update luaunit with the desired functionality, ready for a release
* update the version number in luaunit.lua
* update the version number in doit.py
* check that all tests pass on all supported lua versions: ```doit.py runtests```
    * run functional test: ```lua54.bat run_functional_tests.lua```
        * they should fail because of the version update (the XML captures the version of luaunit used for running them)
        * run WinMerge on the test directory and the ref directory
        * check only the differences between files ending in .xml
        * update the ref/\*.xml files by just updating the version number, nothing else
        * commit the updated files
        * run the functional tests, they should now pass
        * review the changes carefully and commit them: only luaunit version in xml file should be recored
        * check that everything passes with doit.py 
* update *examples* if needed to reflect new features
* update index.rst with documentation of new features/behavior
* update README.md and index.rst with the release information (date and content)
* create a git branch LUAUNIT_VX_X for the packaging process
* GitHub packages:
    * generate package for github: ```doit.py packageit```
    * verify the content of the packages:
        * documentation must be properly generated
        * examples should work
        * unit-tests should pass
        * functional tests should pass
    * merge branch LUAUNIT_VX_X into master
    * push to GitHub to check for CI results and rendering of the README
* LuaRocks packages:
    * rename luaunit-\*.rockspec to the current version
    * generate luarock package:  
* GitHub release:
    * create a release page on GitHub
    * Upload the zip, tgz and rock-luaunit.zip and validate the release
* LuaRocks packages (continued):
    * Copy the url of the rock package in the rock spec
    * upload the rockspec to luarocks
    * run luarocks install luaunit to check that the new version gets installed
    * use the new luaunit and verify the version
* tag the result
