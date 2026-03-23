Annexes
********

.. _table-printing:

Annex A: More on table printing
================================

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

Annex B: Comparing tables with keys of type table
==================================================

There are a few programs out there which use tables as keys for other tables. How to compare
such tables is delicate.

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


The difference between t3 and t4 is that they both reference a key with different table references but
identical table content.

LuaUnit chooses to treat this as two different keys, so t3 and t4 are not considered equal.

.. code-block:: lua

    lu.assertEquals( t3, t4 ) -- fails


If using the same table as key, they are now considered equal:

.. code-block:: lua

    lu.assertEquals( t4, t5 ) -- fails


.. _Source_code_example:

Annex C: Source code of example
=================================

Source code of the example used in the :ref:`getting-started` section

.. code-block:: lua

    --
    -- The examples described in the documentation are below.
    --

    lu = require('luaunit')

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

    function adder(v)
        -- return a function that adds v to its argument using add
        function closure( x ) return x+v end
        return closure
    end

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

    --[[
    --
    --      Uncomment this section to see how failures are displayed
    --
    TestWithFailures = {}
        -- two failing tests

        function TestWithFailures:testFail1()
            lu.assertEquals( "toto", "titi")
        end

        function TestWithFailures:testFail2()
            local a=1
            local b='toto'
            local c = a + b -- oops, can not add string and numbers
            return c
        end
    -- end of table TestWithFailures
    ]]


    --[[
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
            f = io.open(self.fname, 'r')
            lu.assertNotNil( f )
            f:close()
        end

        function TestLogger:tearDown()
            self.fname = 'mytmplog.log'
            -- cleanup our log file after all tests
            os.remove(self.fname)
        end
    -- end of table TestLogger

    ]]

    os.exit(lu.LuaUnit.run())




Annex D: BSD License
====================

    This software is distributed under the BSD License.

    Copyright (c) 2005-2018, Philippe Fremy <phil at freehackers dot org>

    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


