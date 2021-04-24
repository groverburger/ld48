-- expects lume and to exist globally
local lg = love.graphics

local function clamp(n, min, max)
    if min < max then
        return math.min(math.max(n, min), max)
    end

    return math.min(math.max(n, max), min)
end

local function map(n, start1, stop1, start2, stop2, withinBounds)
    local newval = (n - start1) / (stop1 - start1) * (stop2 - start2) + start2

    if not withinBounds then
        return newval
    end

    return clamp(newval, start2, stop2)
end

----------------------------------------------------------------------------------------------------
-- console definition
----------------------------------------------------------------------------------------------------

local console = {
    enabled = false,
    anim = 0,
    text = "",
    wasKeyRepeat = false,
    font = lg.newFont((...):gsub("/console", "") .. "/menlo.ttf", 24),
    lines = {},
    commandHistory = {},
    commandIndex = 1,
    commands = {},
    timer = 0,
}

function console:update(dt)
    local rate = 6
    dt = dt or 1/60
    if self.enabled then
        self.timer = self.timer + dt*4
        self.anim = math.min(self.anim + dt*rate, 1)
    else
        self.anim = math.max(self.anim - dt*rate, 0)
    end
end

function console:draw()
    local r,g,b,a = lg.getColor()
    local anim = self.anim^2

    lg.setColor(0.1,0.1,0.1, 0.75)
    lg.push()
    local height = lg.getHeight()/2
    lg.translate(0, (anim - 1)*height)
    lg.rectangle("fill", 0,0, lg.getWidth(),height)

    local lastFont = lg.getFont()
    lg.setFont(self.font)
    lg.setColor(1,1,1)
    lg.print("> " .. self.text, 8, height - 8 - self.font:getHeight(self.text))
    for i, line in ipairs(self.lines) do
        lg.setColor(1,1,1, map(i, 10,20, 1,0))
        lg.print(line, 8, height - 8 - self.font:getHeight(line)*(i+1))
    end
    lg.setColor(1,1,1, math.sin(self.timer)/2 + 0.5)
    lg.print("  |", 8 + self.font:getWidth(self.text) - self.font:getWidth(" ")/2, height - 8 - self.font:getHeight(self.text))
    lg.setFont(lastFont)
    lg.pop()

    lg.setColor(r,g,b,a)
end

function console:textinput(text)
    if not self.enabled then return end
    if text ~= ":" then
        self.text = self.text .. text
    end
end

function console:addLine(line)
    table.insert(self.lines, 1, line)
    if #self.lines > 20 then
        table.remove(self.lines)
    end
end

function console:addCommand(name, func)
    self.commands[name] = func
end

function console:execute(inputText)
    -- store a list of commands for arrow key shortcuts
    table.insert(self.commandHistory, 1, inputText)
    self:addLine("> " .. inputText)

    local args = lume.split(inputText)

    local function errorCatch(errormsg)
        self:addLine("ERROR: " .. errormsg)
        print(debug.traceback())
    end

    local command = self.commands[args[1]]
    if command then
        xpcall(command, errorCatch, args)
    else
        self:addLine("command unrecognized")
    end
end

function console:keypressed(k)
    local function toggle(enabled)
        if not self.enabled and enabled then
            self.wasKeyRepeat = love.keyboard.hasKeyRepeat()
        end

        self.enabled = enabled
        self.timer = 0
        self.text = ""
        love.keyboard.setKeyRepeat(enabled or self.wasKeyRepeat)
    end

    if k == ";" and (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
        toggle(true)
    end

    if k == "escape" then
        toggle(false)
    end

    if not self.enabled then return end

    if k == "return" then
        self:execute(self.text)
        self.commandIndex = 0
        self.text = ""
    end

    -- queue up the last used command
    if k == "up" then
        self.commandIndex = math.min(self.commandIndex + 1, #self.commandHistory)
        local this = self.commandHistory[self.commandIndex]
        if this then
            self.text = this
        end
    end

    if k == "down" then
        self.commandIndex = math.max(self.commandIndex - 1, 1)
        local this = self.commandHistory[self.commandIndex]
        if this then
            self.text = this
        end
    end

    if k == "backspace" then
        if love.keyboard.isDown("lctrl") then
            -- delete last word
            local lastDeleted
            repeat
                if #self.text == 0 then break end
                lastDeleted = self.text:sub(#self.text, #self.text)
                self.text = self.text:sub(1, #self.text-1)
            until lastDeleted == " "
        else
            -- delete last character
            self.text = self.text:sub(1, #self.text-1)
        end
    end

    return self.enabled
end

console:addCommand("help", function(args)
    for command, _ in pairs(console.commands) do
        console:addLine(command)
    end
end)

console:addCommand("quit", function(args)
    love.event.push("quit")
end)

console:addCommand("q", function(args)
    love.event.push("quit")
end)

console:addLine("console initialized [" .. os.date("%c") .. "]")

return console
