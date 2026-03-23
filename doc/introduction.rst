,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
Welcome to LuaUnit's documentation!
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