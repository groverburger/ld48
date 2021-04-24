engine = require "engine"

function love.load(arg)
    scenemanager.set(FirstScene())
end

function love.update()
    local scene = scenemanager.get()

    if scene.update then
        scene:update()
    end
end

function love.draw()
    local scene = scenemanager.get()

    if scene.draw then
        scene:draw()
    end
end

-- pcalls don't work in web, so this automatically
-- becomes disabled in the release build!
xpcall(require, print, "engine/debugtools")
