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

function utils.deltaLerp(a,b,t, dt)
    return utils.lerp(a,b, 1 - t^(dt))
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

function utils.triangleWave(number)
    return math.acos(math.cos(number*math.pi))/math.pi
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

do
    local function _gradient(amount, index, dimensions, ...)
        local a = select(index, ...)
        local b = select(index + dimensions, ...)

        if index < dimensions then
            return utils.map(amount, 0,1, a,b), _gradient(amount, index+1, dimensions, ...)
        end

        return utils.map(amount, 0,1, a,b)
    end

    function utils.gradient(amount, dimensions, ...)
        assert(select("#", ...) == dimensions*2, "Dimension mismatch! Expected " .. dimensions .. ", given " .. select("#", ...))
        return _gradient(amount, 1, dimensions, ...)
    end
end

function utils.colorGradient(amount, color1, color2)
    local r1,g1,b1 = lume.color(color1)
    local r2,g2,b2 = lume.color(color2)
    return utils.gradient(amount, 3, r1,g1,b1, r2,g2,b2)
end

----------------------------------------------------------------------------------------------------
-- RNG
----------------------------------------------------------------------------------------------------

function utils.randomRange(low,high)
    return math.random()*(high-low) + low
end

-- returns a random element from the given table's array part
function utils.choose(given)
    return given[math.random(#given)]
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

-- 2D implementation
function utils.closestPointOnLineSegment(ax,ay, bx,by, x,y)
    local abx, aby = bx - ax, by - ay
    local t = ((x - ax)*abx + (y - ay)*aby) / (abx^2 + aby^2)
    t = math.min(1, math.max(0, t))
    return ax + t*abx, ay + t*aby
end

-- rotates all points given by angle
-- two-dimensional points only
-- ex: utils.rotatePoints(math.pi/2, 1,2, 3,4)
function utils.rotatePoints(angle, ...)
    local n = select("#", ...)
    local x = select(1, ...)
    local y = select(2, ...)
    local dist = math.sqrt(x^2 + y^2)
    local angle = math.atan2(y,x) + angle
    if n > 2 then
        return math.cos(angle)*dist, math.sin(angle)*dist, utils.rotatePoints(angle, select(3, ...))
    else
        return math.cos(angle)*dist, math.sin(angle)*dist
    end
end

----------------------------------------------------------------------------------------------------
-- file loading
----------------------------------------------------------------------------------------------------

do
    local function recursiveEnumerate(folder, fileList)
        local items = love.filesystem.getDirectoryItems(folder)

        for _, item in ipairs(items) do
            local file = folder .. '/' .. item

            local type = love.filesystem.getInfo(file).type
            if type == "file" then
                table.insert(fileList, file)
            elseif type == "directory" then
                recursiveEnumerate(file, fileList)
            end
        end
    end

    function utils.recursiveEnumerate(folder)
        local fileList = {}
        recursiveEnumerate(folder, fileList)
        return fileList
    end
end

-- require all lua files in a project subfolder automatically
function utils.requireAll(folder)
    local files = utils.recursiveEnumerate(folder)
    local result = {}

    for _, file in ipairs(files) do
        local file = file:sub(1, -5)
        table.insert(result, require(file))
    end

    return result
end

----------------------------------------------------------------------------------------------------
-- misc
----------------------------------------------------------------------------------------------------

function utils.newAnimation(path)
    local anim = {}

    anim.source = love.graphics.newImage(path)
    local width,height = anim.source:getWidth(), anim.source:getHeight()
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
        return tab[start], unpack(tab, start + 1, stop)
    end
end

return utils
