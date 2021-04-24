local input = {}

local mouse = {
    x = love.mouse.getX(),
    y = love.mouse.getY(),
    xMove = 0,
    yMove = 0,
    xLast = love.mouse.getX(),
    yLast = love.mouse.getY(),
}
input.mouse = mouse

----------------------------------------------------------------------------------------------------
-- internal button class
----------------------------------------------------------------------------------------------------

local button = class()
button.keys = {}
button.mouseButtons = {}
button.wasPressed = false

function button:new(name, keys, mouseButtons)
    self.mouseButtons = mouseButtons
    self.keys = keys
    self.name = name

    self.isDown = false
    self.isReleased = false
    self.isPressed = false
    self.wasDown = false
end

function button:update()
    -- determine if this button is down this frame
    self.isDown = false

    for _, btn in pairs(self.mouseButtons) do
        if love.mouse.isDown(btn) then
            self.isDown = true
            break
        end
    end

    if not self.isDown then
        for _, key in pairs(self.keys) do
            if love.keyboard.isDown(key) then
                self.isDown = true
                break
            end
        end
    end

    -- update these one-frame events
    self.isPressed = not self.wasDown and self.isDown
    if self.isPressed then
        input.onPressed(self.name)
    end

    self.isReleased = self.wasDown and not self.isDown
    if self.isReleased then
        input.onReleased(self.name)
    end

    -- save isDown for next frame
    self.wasDown = self.isDown
end

----------------------------------------------------------------------------------------------------
-- buttons api
----------------------------------------------------------------------------------------------------

local buttonList = {}
function input.addButton(name, ...)
    buttonList[name] = button(name, ...)
    return buttonList[name]
end

function input.update()
    for name, btn in pairs(buttonList) do
        btn:update()
    end
    mouse.xLast = mouse.x
    mouse.yLast = mouse.y
    local width, height = engine.settings.gameWidth, engine.settings.gameHeight

    if width and height then
        local size = math.min(lg.getWidth()/width, lg.getHeight()/height)
        mouse.x = utils.map(love.mouse.getX(), lg.getWidth()/2 - width*size/2, lg.getWidth()/2 + width*size/2, 0, width)
        mouse.y = utils.map(love.mouse.getY(), lg.getHeight()/2 - height*size/2, lg.getHeight()/2 + height*size/2, 0, height)
    else
        mouse.x, mouse.y = love.mouse.getPosition()
    end

    mouse.xMove = mouse.x - mouse.xLast
    mouse.yMove = mouse.y - mouse.yLast
end

function input.isDown(btn)
    local btn = buttonList[btn]
    return btn and btn.isDown
end

function input.isPressed(btn)
    local btn = buttonList[btn]
    return btn and btn.isPressed
end

function input.isReleased(btn)
    local btn = buttonList[btn]
    return btn and btn.isReleased
end

-- override these!
function input.onPressed(btn) end
function input.onReleased(btn) end

return input
