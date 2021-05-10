Cutscene = class()

function Cutscene:new(throne)
    self.drawcalls = {}
end

function Cutscene:update()
    if coroutine.status(self.routine) ~= "dead" then
        lume.clear(self.drawcalls)
        local success, value = coroutine.resume(self.routine)
        assert(success, value)
    else
        self.dead = true
    end
end

-- unpack from the second place in the table
local function unpack2(tab, start, stop)
    if not start then start = math.min(2, #tab) end
    if not stop then stop = #tab end

    if start == stop then
        return tab[start]
    elseif start < stop then
        return tab[start], unpack(tab, start + 1, stop)
    end
end

-- this is absolutely atrocious
-- but necessary because lua treats nil as an argument in varargs
function Cutscene:draw()
    for _, drawcall in ipairs(self.drawcalls) do
        if drawcall[1] then
            if #drawcall > 1 then
                drawcall[1](unpack2(drawcall))
            else
                drawcall[1]()
            end
        end
    end
end
