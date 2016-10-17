
lu = require('luaunit')

-- improved diagnosis is not for:
-- * nested lists or nested dictionnaries
-- * dictonnaries
-- * list with lengh < 2

-- improved diagnosis is for:
-- * list with plain values (number, boolean, strings, function, thread, userdata)
-- * list with length > 2

-- small list of numbers
function test1()
    local A, B = { 1212212, 12221122, 12211221, 122122212, 111221212121 }, { 1212212, 12221122, 12121221, 122122212, 111221212121 }
    lu.assertEquals( A, B )
end

function test1b()
    local A, B = { 1212212, 12221122, 12211221 }, { 1212212, 12221122, 12121221 }
    lu.assertEquals( A, B )
end

function test1c()
    local A, B = { 12211221, 122122212, 111221212121 }, { 12121221, 122122212, 111221212121 }
    lu.assertEquals( A, B )
end


function range(start, stop)
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

-- long list of numbers, same size, swapped values
function test2()
    local stop=20
    local x=7
    local A, B = range(1,20), range(1,20)
    B[x], B[x+1] = B[x+1], B[x]
    lu.assertEquals( A, B )
end

-- long list of numbers, one hole
function test3()
    local stop=20
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
function test4()
    local stop=20
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
function sub_test5()
    local stop=20
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

function test5a()
    local A, B = sub_test5()
    lu.ORDER_ACTUAL_EXPECTED = false
    lu.assertEquals( A, B )
end

function test5b()
    local A, B = sub_test5()
    lu.ORDER_ACTUAL_EXPECTED = true
    lu.assertEquals( B, A )
end

function test5c()
    local A, B = sub_test5()
    lu.PRINT_TABLE_REF_IN_ERROR_MSG = true
    lu.assertEquals( B, A )
end

function test5d()
    lu.PRINT_TABLE_REF_IN_ERROR_MSG = false
end

function test6()
    local f1 = function () return nil end
    local t1 = coroutine.create( function(v) local y=v+1 end )
    local A = { 'aaa', 'bbb', 'ccc', f1, 1.0, 2.0, nil, true, false, t1, t1, t1 }
    local B = { 'aaa', 'bbb', 'ccc', f1, 1.0, 2.0, nil, false, false, t1, t1, t1 }
    lu.assertEquals( B, A )
end

function test7()
    local A = { {1,2,3}, {1,2}, { {1}, {2} }, { 'aa', 'cc'}, 1, 2 }
    local B = { {1,2,3}, {1,2}, { {2}, {2} }, { 'aa', 'bb'}, 1, 2 }
    lu.assertEquals( B, A )
end



os.exit( lu.run() )