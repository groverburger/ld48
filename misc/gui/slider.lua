GuiSlider = class()
GuiSlider.controller = "menu"
GuiSlider.button = "ok"

function GuiSlider:new(table, key, value)
    self.value = value or 0.5
    self.grabbed = false
    self.table = table
    self.key = key or 1
end

function GuiSlider:draw(x,y,w,h)
    lg.setColor(1,1,1, 0.75)
    local r = 8
    local x = x + r+1
    local w = w - (r+1)*2
    local y = y + r+1+8
    local vx = utils.lerp(x, x + w, self.value)

    -- do the behavior
    if input.controllers[self.controller]:pressed(self.button)
    and not self.grabbed then
        if utils.distance(input.mouse.x, input.mouse.y, vx, y) <= r then
            self.grabbed = true
            self.offset = vx - input.mouse.x
        elseif math.abs(y - input.mouse.y) <= r and math.abs((x+x+w)/2 - input.mouse.x) <= w/2 then
            self.grabbed = true
            self.offset = 0
        end
    end
    self.grabbed = self.grabbed and input.controllers[self.controller]:down(self.button)
    if self.grabbed then
        self.value = utils.map(input.mouse.x + self.offset, x, x+w, 0, 1, true)
        self.table[self.key] = self.value
    end

    -- draw line and circle
    local vx = utils.lerp(x, x + w, self.value)
    local lw = lg.getLineWidth()
    lg.setLineWidth(lw + 3)
    lg.line(x, y, vx, y)
    lg.setLineWidth(lw)
    lg.line(vx, y, x + w, y)
    lg.setColor(1,1,1)
    lg.circle("fill", vx, y, r)
end
