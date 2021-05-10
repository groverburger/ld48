GuiSlider = class()

function GuiSlider:new(value)
    self.value = value or 0.5
    self.grabbed = false
end

function GuiSlider:draw(x,y,w,h)
    lg.setColor(1,1,1, 0.75)
    local r = 8
    local x = x + r+1
    local w = w - (r+1)*2
    local y = y + r+1+8
    local vx = utils.lerp(x, x + w, self.value)

    -- do the behavior
    if utils.distance(input.mouse.x, input.mouse.y, vx, y) <= r+4
    and input.isPressed("leftmouse")
    and not self.grabbed then
        self.grabbed = true
        self.offset = vx - input.mouse.x
    end
    self.grabbed = self.grabbed and input.isDown("leftmouse")
    if self.grabbed then
        self.value = utils.map(input.mouse.x + self.offset, x, x+w, 0, 1, true)
    end

    local vx = utils.lerp(x, x + w, self.value)
    lg.line(x, y, x + w, y)
    lg.setColor(1,1,1)
    lg.circle("fill", vx, y, r)
end
