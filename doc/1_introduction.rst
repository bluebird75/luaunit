,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
LuaUnit's documentation!
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,


Introduction
************

LuaUnit is a popular unit-testing framework for Lua, with an interface typical
of xUnit libraries (Python unittest, Junit, NUnit, ...). It supports
several output formats (Text, TAP, JUnit, ...) to be used directly or work with Continuous Integration platforms
(Jenkins, Hudson, ...).

For simplicity, LuaUnit is contained into a single-file and has no external dependency. To start using it,
just add the file *luaunit.lua* to your project. A `LuaRocks package`_  is also available.

.. _LuaRocks package: https://luarocks.org/modules/bluebird75/luaunit

Tutorial and reference documentation is available on `Read-the-docs`_ .

.. _Read-the-docs: http://luaunit.readthedocs.org/en/latest/

LuaUnit also provides some dedicated support to scientific computing.

LuaUnit may also be used as an assertion library. In that case, you will call the assertion functions, which generate errors
when the assertion fails. The error includes a detailed analysis of the failed assertion, like when executing a test suite.

LuaUnit provides another generic usage function: :lua:func:`prettystr` which converts any value to a nicely
formatted string. It supports in particular tables, nested table and even recursive tables.


More details
************

LuaUnit provides a wide range of assertions and goes into great efforts to provide the most useful output. For example
since version 3.3 , comparing lists will provide a detailed difference analysis:

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


The command-line options provide a flexible interface to select tests by name or patterns, control output
format, set verbosity and more. See `Using the command-line`_ .

LuaUnit is very well tested: code coverage is 99.5% . The test suite is run on every version of Lua (Lua 5.1 to 5.3, LuaJIT 2.0 and 2.1 beta)
and on many OS (Windows Seven, Windows Server 2012, MacOs X and Ubuntu). You can check the continuous build results on `Travis-CI`_ and `AppVeyor`_ .

.. _Travis-CI: https://travis-ci.org/bluebird75/luaunit
.. _AppVeyor: https://ci.appveyor.com/project/bluebird75/luaunit/history

LuaUnit is maintained on GitHub: https://github.com/bluebird75/luaunit . We gladly accept feature requests and even better Pull Requests.

LuaUnit is released under the BSD license.


Installation
************

LuaUnit is packed into a single-file. To make start using it, just add the file to your project. 

Several installation methods are available.

LuaRocks
===========

LuaUnit is available as a `LuaRocks package`_ .

.. _LuaRocks package: https://luarocks.org/modules/bluebird75/luaunit

GitHub
==========

The simplest way to install LuaUnit is to fetch the GitHub version:

.. code-block:: bash

    git clone git@github.com:bluebird75/luaunit.git

Then copy the file luaunit.lua into your project or the Lua libs directory.

The version in development on GitHub is always stable and can be used safely.

On Linux, you can also install it into your Lua directories

.. code-block:: bash

    sudo python doit.py install

If that fail, edit the function *install()* in the file *doit.py* to adjust
the Lua version and installation directory. It uses, by default, Linux paths that depend on the version.

