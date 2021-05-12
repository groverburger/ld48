local input = {}
local controllers = {}
local baton = require(engine.path .. "/baton")
local mouse = {
    x = love.mouse.getX(),
    y = love.mouse.getY(),
    xMove = 0,
    yMove = 0,
    xLast = love.mouse.getX(),
    yLast = love.mouse.getY(),
}
input.mouse = mouse
input.controllers = controllers

function input.newController(name, ...)
    local this = baton.new(...)
    controllers[name] = this
    return this
end

function input.update()
    for _, c in pairs(controllers) do
        c:update()
    end

    mouse.xLast = mouse.x
    mouse.yLast = mouse.y
    local width, height = engine.settings.gamewidth, engine.settings.gameheight

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

return input
