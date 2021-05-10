love.window.setIcon(love.image.newImageData("assets/sprites/gameicon.png"))

function love.load(arg)
    scene(TitleScene())
end

function love.update()
    local scene = scene()
    if scene.update then
        scene:update()
    end
end

function love.draw()
    local scene = scene()
    if scene.draw then
        scene:draw()
    end
end

love.run = require "engine" {
    gameWidth = 1024,
    gameHeight = 768,
}

input.addButton("left", {"a"})
input.addButton("right", {"d"})
input.addButton("jump", {"space", "w"})
input.addButton("shoot", {}, {1,2,3})
