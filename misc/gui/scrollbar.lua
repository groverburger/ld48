GuiScrollbarV = class()
GuiScrollbarV.controller = "menu"
GuiScrollbarV.button = "ok"

function GuiScrollbarV:new(scrollform)
    self.scrollform = scrollform
end

function GuiScrollbarV:draw(ox,oy,ow,oh)
    local form = self.scrollform
    local h = (form.vh / form.totalh) * oh
    local w = ow
    local y = oy + utils.map(form.vy, 0, form.totalh - form.vh, 0, oh - h)
    local x = ox

    if input.controllers[self.controller]:pressed(self.button) then
        if  input.mouse.x >= x   and input.mouse.y >= y
        and input.mouse.x <= x+w and input.mouse.y <= y+h then
            self.grabbed = true
            self.ox = x - input.mouse.x
            self.oy = y - input.mouse.y
        end
    end

    self.grabbed = self.grabbed and input.controllers[self.controller]:down(self.button)

    if self.grabbed then
        y = utils.clamp(input.mouse.y + self.oy, oy, oy+oh-h)
        local frac = utils.map(y, oy, oy+oh-h, 0, 1)
        form:setScrollAmount(0, frac)
    end

    lg.setColor(1,1,1)
    lg.rectangle("fill", x,y,w,h)
end

GuiScrollbarH = class()
GuiScrollbarH.controller = "menu"
GuiScrollbarH.button = "ok"

function GuiScrollbarH:new(scrollform)
    self.scrollform = scrollform
end

function GuiScrollbarH:draw(ox,oy,ow,oh)
    local form = self.scrollform
    local h = oh
    local w = (form.vw / form.totalw) * ow
    local y = oy
    local x = ox + utils.map(form.vx, 0, form.totalw - form.vw, 0, ow - w)

    if input.controllers[self.controller]:pressed(self.button) then
        if  input.mouse.x >= x   and input.mouse.y >= y
        and input.mouse.x <= x+w and input.mouse.y <= y+h then
            self.grabbed = true
            self.ox = x - input.mouse.x
            self.oy = y - input.mouse.y
        end
    end

    self.grabbed = self.grabbed and input.controllers[self.controller]:down(self.button)

    if self.grabbed then
        x = utils.clamp(input.mouse.x + self.ox, ox, ox+ow-w)
        local frac = utils.map(x, ox, ox+ow-w, 0, 1)
        form:setScrollAmount(frac, 0)
    end

    lg.setColor(1,1,1)
    lg.rectangle("fill", x,y,w,h)
end
