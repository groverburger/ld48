GuiForm = class()
GuiForm.controller = "menu"
GuiForm.scrollup = "scrollup"
GuiForm.scrolldown = "scrolldown"
GuiForm.freeScroll = true

function GuiForm:new(x,y,w,h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    -- the view dimensions for scrolling relative to current position
    self.vx = 0
    self.vy = 0
    self.vw = w
    self.vh = h
    -- the original dimensions for graphical scissor
    self.ox = x
    self.oy = y
    self.ow = w
    self.oh = h
    -- the total width and height that gets added when setScrollable adds more
    self.totalw = w
    self.totalh = h

    self.margin = 4
    self.children = {}
    self.align = "left"
end

function GuiForm:cut(side, amount)
    local class = self:getClass()

    if side == "right" then
        self.w = math.max(self.w - amount, 0)
        local n = class(self.x + self.w, self.y, amount, self.h)
        n.showingBorder = self.showingBorder
        n.font = self.font
        table.insert(self.children, n)
        return n
    end

    if side == "left" then
        self.x = self.x + amount
        self.w = math.max(self.w - amount, 0)
        local n = class(self.x - amount, self.y, amount, self.h)
        n.showingBorder = self.showingBorder
        n.font = self.font
        table.insert(self.children, n)
        return n
    end

    if side == "bottom" then
        self.h = math.max(self.h - amount, 0)
        local n = class(self.x, self.y + self.h, self.w, amount)
        n.showingBorder = self.showingBorder
        n.font = self.font
        table.insert(self.children, n)
        return n
    end

    if side == "top" then
        self.y = self.y + amount
        self.h = math.max(self.h - amount, 0)
        local n = class(self.x, self.y - amount, self.w, amount)
        n.showingBorder = self.showingBorder
        n.font = self.font
        table.insert(self.children, n)
        return n
    end

    error("GuiForm side " .. side .. " does not exist!")
end

function GuiForm:undercut(...)
    self:cut(...)
    return self
end

function GuiForm:setContent(what)
    self.content = what
    return self
end

function GuiForm:attach(what)
    self.attached = what
    return self
end

function GuiForm:setAlign(what)
    self.align = what
    return self
end

function GuiForm:setMargin(what)
    self.margin = what
    return self
end

function GuiForm:setBorder(what)
    self.showingBorder = what
    return self
end

function GuiForm:setFont(what)
    self.font = what
    return self
end

function GuiForm:setScrollable(dir, amount, scrollbar)
    if dir == "down" then
        if scrollbar then
            local scroll = self:cut("left", self.w-(tonumber(scrollbar) or 10)):setScrollable(dir, amount)
            self:attach(GuiScrollbarV(scroll))
            return scroll, self
        end
        self.scrolldir = dir
        self.h = self.h + amount
        self.totalh = self.totalh + amount
        return self
    end

    if dir == "right" then
        if scrollbar then
            local scroll = self:cut("top", self.h-(tonumber(scrollbar) or 10)):setScrollable(dir, amount)
            self:attach(GuiScrollbarH(scroll))
            return scroll, self
        end
        self.scrolldir = dir
        self.w = self.w + amount
        self.totalw = self.totalw + amount
        return self
    end

    error(dir .. " is not a valid GuiForm scroll direction!")
end

function GuiForm:scroll(dx,dy)
    assert(self.scrolldir, "This GuiForm is not scrollable!")
    self.vx = self.vx + dx
    self.vy = self.vy + dy
    return self
end

function GuiForm:setScrollAmount(x,y)
    assert(self.scrolldir, "This GuiForm is not scrollable!")
    self.vx = utils.lerp(0, self.totalw - self.vw, x or 0)
    self.vy = utils.lerp(0, self.totalh - self.vh, y or 0)
    return self
end

function GuiForm:draw(xoff,yoff)
    if not self.scrolldir then
        -- keep all children in view when not scrolling
        self.vx = 0
        self.vy = 0
        self.vw = self.ow
        self.vh = self.oh
    else
        -- keep scroll in bounds when scrolling
        self.vx = utils.clamp(self.vx, 0, self.totalw - self.vw)
        self.vy = utils.clamp(self.vy, 0, self.totalh - self.vh)
    end

    -- if this is the top-level form, save the previous graphics transform
    -- in case there was a scissor going on up there
    local original = xoff == nil
    if original then lg.push("all") end

    local xoff = xoff and utils.round(xoff) or 0
    local yoff = yoff and utils.round(yoff) or 0

    -- get previous scissor, and intersect with it
    local sx,sy,sw,sh = lg.getScissor()
    if sx then
        lg.intersectScissor(xoff + self.ox, yoff + self.oy, self.vw, self.vh)
    else
        lg.setScissor(xoff + self.ox, yoff + self.oy, self.ow, self.oh)
    end

    -- let the user use their scroll buttons when hovering
    local _sx,_sy,_sw,_sh = lg.getScissor()
    if  input.mouse.x >= _sx     and input.mouse.y >= _sy
    and input.mouse.y <= _sx+_sw and input.mouse.y <= _sy+_sw and self.freeScroll then
        if input.controllers[self.controller]:down(self.scrollup) then
            self.vy = self.vy - 8
        end
        if input.controllers[self.controller]:down(self.scrolldown) then
            self.vy = self.vy + 8
        end

        self.vx = utils.clamp(self.vx, 0, self.totalw - self.vw)
        self.vy = utils.clamp(self.vy, 0, self.totalh - self.vh)
    end

    local xoff = xoff - self.vx
    local yoff = yoff - self.vy
    local dx, dy = xoff + self.x, yoff + self.y

    -- draw background
    lg.setColor(0,0,0, 0.85)
    lg.rectangle("fill", dx,dy,self.w,self.h)

    -- draw content
    local prevFont = lg.getFont()
    if self.font then lg.setFont(self.font) end
    self:drawContent(xoff,yoff)
    lg.setFont(prevFont)

    -- draw border, if this form has one
    if self.showingBorder then
        local w = lg.getLineWidth()
        lg.setColor(1,1,1)
        lg.setLineWidth(2)
        lg.rectangle("line", dx,dy,self.w,self.h)
        lg.setLineWidth(w)
    end

    -- reset previous scissor
    lg.setScissor(sx,sy,sw,sh)
    if original then lg.pop("all") end
end

function GuiForm:drawContent(xoff,yoff)
    lg.setColor(1,1,1)
    local dx, dy = (xoff or 0) + self.x, (yoff or 0) + self.y

    -- draw the children
    for _, child in ipairs(self.children) do
        child:draw(xoff,yoff)
    end

    -- draw attached element only when it is visible
    -- this prevents elements out of scrollview from being interacted with
    local sx,sy,sw,sh = lg.getScissor()
    if self.attached and sw > 0 and sh > 0 then
        self.attached:draw(dx,dy,self.w,self.h)
    end

    -- draw content of this guiform
    if not self.content then return end

    local m = self.margin
    lg.setColor(1,1,1)

    -- if content is a string, then print it and wrap it
    if type(self.content) == "string" then
        lg.printf(self.content, dx + m, dy + m, self.w - m*2, self.align)
    end

    -- if content is an image, then draw it to fill the rect
    if type(self.content) == "userdata" and self.content.typeOf and self.content:typeOf("Image") then
        local sx,sy = self.w/self.content:getWidth(), self.h/self.content:getHeight()
        lg.draw(self.content, dx, dy, 0, sx, sy)
    end
end
