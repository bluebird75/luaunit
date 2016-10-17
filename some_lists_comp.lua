
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
    local cmp = { { 1212212, 12221122, 12211221, 122122212, 111221212121 }, { 1212212, 12221122, 12121221, 122122212, 111221212121 } }
    lu.assertEquals( cmp[1], cmp[2])
end

function test1b()
    local cmp = { { 1212212, 12221122, 12211221 }, { 1212212, 12221122, 12121221 } }
    lu.assertEquals( cmp[1], cmp[2])
end

function test1c()
    local cmp = { { 12211221, 122122212, 111221212121 }, { 12121221, 122122212, 111221212121 } }
    lu.assertEquals( cmp[1], cmp[2])
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
    local cmp = { range(1,20), range(1,20) }
    cmp[2][x], cmp[2][x+1] = cmp[2][x+1], cmp[2][x]
    lu.assertEquals( cmp[1], cmp[2])
end

-- long list of numbers, one hole
function test3()
    local stop=20
    local x=7
    local cmp = { range(1,20), {} }
    local i=1
    while i <= #cmp[1] do
        if i ~= x then
            table.insert( cmp[2], cmp[1][i] )
        end
        i = i + 1
    end
    lu.assertEquals( cmp[1], cmp[2])
end


-- long list of numbers, one bigger hole
function test4()
    local stop=20
    local x=7
    local x2=8
    local x3=9
    local cmp = { range(1,20), {} }
    local i=1
    while i <= #cmp[1] do
        if i ~= x and i ~= x2 and i ~= x3 then
            table.insert( cmp[2], cmp[1][i] )
        end
        i = i + 1
    end
    lu.assertEquals( cmp[1], cmp[2])
end


function sub_test5()
    local stop=20
    local x=7
    local x2=8
    local x3=9
    local cmp = { range(1,20), {} }
    local i=1
    while i <= #cmp[1] do
        if i ~= x and i ~= x2 and i ~= x3 then
            table.insert( cmp[2], cmp[1][i] )
        end
        i = i + 1
    end
    x = 5
    cmp[2][x], cmp[2][x+1] = cmp[2][x+1], cmp[2][x]
    return cmp
end

function test5a()
    local cmp = sub_test5()
    lu.assertEquals( cmp[1], cmp[2])
end

function test5b()
    local cmp = sub_test5()
    lu.assertEquals( cmp[2], cmp[1])
end

-- test1()
lu.run()