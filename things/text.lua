require "things/thing"

Text = class(Thing)

local font = lg.newFont("assets/comicneuebold.ttf", 32)

function Text:new(x, y)
    Text.super.new(self, x, y)
end

function Text:draw()
    lg.setFont(font)
    local scene = scene()
    local alpha = 1 - math.abs(self.levelIndex - scene.levelIndex - scene.depthOffset)
    self.message = self.message and string.gsub(self.message, "#", "\n") or "message wasn't loaded!"

    local dx, dy = self.x - font:getWidth(self.message)/2, self.y

    colors.white(alpha)
    local r = 3
    for i=0, math.pi*2, math.pi*2/10 do
        local dx, dy = dx + math.cos(i)*r, dy + math.sin(i)*r
        lg.print(self.message, dx,dy)
    end

    colors.black(alpha)
    lg.print(self.message, dx,dy)

    colors.white()
end
