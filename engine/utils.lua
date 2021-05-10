----------------------------------------------------------------------------------------------------
-- useful math utility functions
----------------------------------------------------------------------------------------------------

local utils = {}

----------------------------------------------------------------------------------------------------
-- wave and conversion functions
----------------------------------------------------------------------------------------------------

function utils.lerp(a,b,t)
    return (1-t)*a + t*b
end

-- decimal determines to what decimal point it should round
-- different case for negative numbers to round them correctly
function utils.round(n, decimal)
    decimal = decimal or 0
    local pow = 10^decimal
    return (n >= 0 and math.floor(n*pow + 0.5) or math.ceil(n*pow - 0.5))/pow
end

function utils.sigmoid(n)
    return 1/(1+2.71828^(-1*n))
end

function utils.sign(n)
    return (n > 0 and 1) or (n < 0 and -1) or 0
end

function utils.clamp(n, min, max)
    if min < max then
        return math.min(math.max(n, min), max)
    end

    return math.min(math.max(n, max), min)
end

function utils.map(n, start1, stop1, start2, stop2, withinBounds)
    local newval = (n - start1) / (stop1 - start1) * (stop2 - start2) + start2

    if not withinBounds then
        return newval
    end

    return utils.clamp(newval, start2, stop2)
end

----------------------------------------------------------------------------------------------------
-- RNG
----------------------------------------------------------------------------------------------------

function utils.randomRange(low,high)
    return math.random()*(high-low) + low
end

-- returns a random element from the given table's array part
function utils.choose(...)
    local count = select("#", ...)
    assert(count > 0, "Nothing provided to choose from!")
    local first = select(1, ...)

    -- if there's only one argument and it's a table, choose from that instead
    if count == 1 and type(first) == "table" then
        return first[math.random(#first)]
    end

    -- store in a local so we don't multi-return
    local ret = select(math.random(count), ...)
    return ret
end

function utils.randomish(number)
    return (math.sin(number*37.8)*1001 % 70 - 35) / 35
end

----------------------------------------------------------------------------------------------------
-- vector functions
----------------------------------------------------------------------------------------------------

function utils.distance3d(x1,y1,z1, x2,y2,z2)
    return ((x2-x1)^2+(y2-y1)^2+(z2-z1)^2)^0.5
end

function utils.distance(x1,y1, x2,y2)
    return ((x2-x1)^2+(y2-y1)^2)^0.5
end

function utils.lengthdir(angle, length)
    return math.cos(angle)*length, math.sin(angle)*length
end

-- returns the angle between two points
function utils.angle(x1,y1, x2,y2)
    if x2 and y2 then
        return math.atan2(y2-y1, x2-x1)
    end

    return math.atan2(y1,x1)
end

----------------------------------------------------------------------------------------------------
-- misc
----------------------------------------------------------------------------------------------------

-- creates an animation from a horizontal animation strip
-- assume all elements are squares based on the height of the strip
function utils.newAnimation(path)
    local anim = {}
    anim.source = love.graphics.newImage(path)
    local width, height = anim.source:getWidth(), anim.source:getHeight()
    anim.size = height

    for i=0, math.floor(width/height) do
        local x = i*height
        anim[i+1] = love.graphics.newQuad(x,0, height,height, width,height)
    end

    return anim
end

-- unpacks a table like in lua 5.2
function utils.unpack(tab, start, stop)
    if not start then start = math.min(1, #tab) end
    if not stop then stop = #tab end

    if start == stop then
        return tab[start]
    else
        return tab[start], utils.unpack(tab, start + 1, stop)
    end
end

return utils
