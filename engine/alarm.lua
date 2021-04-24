Alarm = class()

local function unpack(tab, start, stop)
    if not start then start = math.min(1, #tab) end
    if not stop then stop = #tab end

    if start == stop then
        return tab[start]
    else
        return tab[start], unpack(tab, start + 1, stop)
    end
end

function Alarm:new(callback, ...)
    self.callback = callback
    self.time = math.huge
    self.lastTime = math.huge
    self.args = {...}
end

function Alarm:set(timeLower, timeUpper)
    self.settingLower = timeLower
    assert(not timeUpper or timeUpper > timeLower,
        "Alarm upper bound must be greater than its lower bound! (" .. tostring(timeLower) .. ", " .. tostring(timeUpper) .. ")")
    self.settingUpper = timeUpper

    return self:reset()
end

function Alarm:reset()
    assert(self.settingLower, "Alarm must be set before it is reset!")

    if self.settingUpper then
        self.time = self.settingLower + math.random()*(self.settingUpper-self.settingLower)
    else
        self.time = self.settingLower
    end

    self.lastTime = self.time

    return self
end

function Alarm:unset()
    self.time = math.huge
end

function Alarm:isActive()
    return self.time ~= math.huge
end

function Alarm:getProgress(interpolation)
    return math.min(1 - self.time / self.lastTime, 1)
end

function Alarm:update(dt)
    self.time = self.time - (dt or 1)
    if self.time <= 0 then
        self.time = math.huge
        if self.callback then
            self.callback(unpack(self.args))
        end
    end
end

return Alarm
