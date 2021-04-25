require "things/thing"

Text = class(Thing)

local font = lg.newFont("assets/comicneuebold.ttf", 32)
lg.setFont(font)

function Text:new(x, y)
    Text.super.new(self, x, y)
end

function Text:draw()
    local scene = scenemanager.get()
    local alpha = 1 - math.abs(self.levelIndex - scene.levelIndex - scene.depthOffset)
    colors.black(alpha)
    self.message = self.message or "message wasn't loaded!"
    lg.print(self.message, self.x - font:getWidth(self.message)/2, self.y)
    colors.white()
end
