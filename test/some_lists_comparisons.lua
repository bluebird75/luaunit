
local lu = require('luaunit')

local function range(start, stop)
    -- return list of { start ... stop }
    local i 
    local ret = {}
    i=start
    while i <= stop do
        table.insert(ret, i)
        i = i + 1
    end
    return ret
end


TestListCompare = {}

    function TestListCompare:test1()
        local A = { 121221, 122211, 121221, 122211, 121221, 122212, 121212, 122112, 122121, 121212, 122121 } 
        local B = { 121221, 122211, 121221, 122211, 121221, 122212, 121212, 122112, 121221, 121212, 122121 }
        lu.assertEquals( A, B )
    end

    function TestListCompare:test1b()
        local A = { 121221, 122211, 121221, 122112, 121212, 121122, 121212, 122122, 121212, 122112, 122112 }
        local B = { 121221, 122211, 121221, 122112, 121212, 121122, 121212, 122122, 121212, 122112, 121212 }
        lu.assertEquals( A, B )
    end

    function TestListCompare:test1c()
        local A = { 122112, 122121, 111212, 122121, 122121, 121212, 121121, 121212, 121221, 122212, 112121 } 
        local B = { 121212, 122121, 111212, 122121, 122121, 121212, 121121, 121212, 121221, 122212, 112121 }
        lu.assertEquals( A, B )
    end


    -- long list of numbers, same size, swapped values
    function TestListCompare:test2()
        local x=7
        local A, B = range(1,20), range(1,20)
        B[x], B[x+1] = B[x+1], B[x]
        lu.assertEquals( A, B )
    end

    -- long list of numbers, one hole
    function TestListCompare:test3()
        local x=7
        local A, B = range(1,20), {}
        local i=1
        while i <= #A do
            if i ~= x then
                table.insert( B, A[i] )
            end
            i = i + 1
        end
        lu.assertEquals( A, B )
    end


    -- long list of numbers, one bigger hole
    function TestListCompare:test4()
        local x=7
        local x2=8
        local x3=9
        local A, B = range(1,20), {}
        local i=1
        while i <= #A do
            if i ~= x and i ~= x2 and i ~= x3 then
                table.insert( B, A[i] )
            end
            i = i + 1
        end
        lu.assertEquals( A, B )
    end

    -- long list, difference + big hole
    function TestListCompare:sub_test5()
        local x=7
        local x2=8
        local x3=9
        local A, B = range(1,20), {}
        local i=1
        while i <= #A do
            if i ~= x and i ~= x2 and i ~= x3 then
                table.insert( B, A[i] )
            end
            i = i + 1
        end
        x = 5
        B[x], B[x+1] = B[x+1], B[x]
        return A, B
    end

    function TestListCompare:test5a()
        local A, B = self:sub_test5()
        lu.ORDER_ACTUAL_EXPECTED = false
        lu.assertEquals( A, B )
    end

    function TestListCompare:test5b()
        local A, B = self:sub_test5()
        lu.assertEquals( B, A )
    end

    function TestListCompare:test5c()
        local A, B = self   :sub_test5()
        lu.PRINT_TABLE_REF_IN_ERROR_MSG = true
        lu.assertEquals( B, A )
    end

    function TestListCompare:test6()
        local f1 = function () return nil end
        local t1 = coroutine.create( function(v) local y=v+1 end )
        local A = { 'aaa', 'bbb', 'ccc', f1, 1.1, 2.1, nil, true, false, t1, t1, t1 }
        local B = { 'aaa', 'bbb', 'ccc', f1, 1.1, 2.1, nil, false, false, t1, t1, t1 }
        lu.assertEquals( B, A )
    end

    function TestListCompare:test7()
        local A = { {1,2,3}, {1,2}, { {1}, {2} }, { 'aa', 'cc'}, 1, 2, 1.33, 1/0, { a=1 }, {} }
        local B = { {1,2,3}, {1,2}, { {2}, {2} }, { 'aa', 'bb'}, 1, 2, 1.33, 1/0, { a=1 }, {} }
        lu.assertEquals( B, A )
    end

    function TestListCompare:tearDown()
        -- cancel effect of test5a
        lu.ORDER_ACTUAL_EXPECTED = true
        -- cancel effect of test5c
        lu.PRINT_TABLE_REF_IN_ERROR_MSG = false
    end
-- end TestListCompare

--[[
TestDictCompare = {}
    function XTestDictCompare:test1()
        lu.assertEquals( {one=1,two=2, three=3}, {one=1,two=1, three=3} )
    end

    function XTestDictCompare:test2()
        lu.assertEquals( {one=1,two=2, three=3, four=4, five=5}, {one=1,two=1, three=3, four=4, five=5} )
    end
-- end TestDictCompare
]]

    
os.exit( lu.run() )