Interface = class()

local uifont = lg.newFont("assets/comicneuebold.ttf", 20)

function Interface:new(x,y,w,h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.margin = 4
    self.children = {}
    self.align = "left"
    self.showingBorder = false
end

function Interface:cut(side, amount)
    local class = self:getClass()

    if side == "right" then
        self.w = math.max(self.w - amount, 0)
        local n = class(self.x + self.w, self.y, amount, self.h)
        n.showingBorder = self.showingBorder
        table.insert(self.children, n)
        return n
    end

    if side == "left" then
        self.x = self.x + amount
        self.w = math.max(self.w - amount, 0)
        local n = class(self.x - amount, self.y, amount, self.h)
        n.showingBorder = self.showingBorder
        table.insert(self.children, n)
        return n
    end

    if side == "bottom" then
        self.h = math.max(self.h - amount, 0)
        local n = class(self.x, self.y + self.h, self.w, amount)
        n.showingBorder = self.showingBorder
        table.insert(self.children, n)
        return n
    end

    if side == "top" then
        self.y = self.y + amount
        self.h = math.max(self.h - amount, 0)
        local n = class(self.x, self.y - amount, self.w, amount)
        n.showingBorder = self.showingBorder
        table.insert(self.children, n)
        return n
    end

    error("Interface side " .. side .. " does not exist!")
end

-- convenience function for chaining, mainly for padding things out
function Interface:undercut(...)
    self:cut(...)
    return self
end

function Interface:setContent(what)
    self.content = what
    return self
end

function Interface:attach(what)
    self.attached = what
    return self
end

function Interface:setAlign(what)
    self.align = what
    return self
end

function Interface:setMargin(what)
    self.margin = what
    return self
end

function Interface:showBorder()
    self.showingBorder = true
    return self
end

function Interface:draw()
    lg.setColor(0,0,0, 0.85)
    lg.rectangle("fill", self.x,self.y,self.w,self.h)
    lg.setColor(1,1,1)
    if self.showingBorder then
        lg.rectangle("line", self.x,self.y,self.w,self.h)
    end

    local prevFont = lg.getFont()
    lg.setFont(uifont)
    self:drawContent()
    lg.setFont(prevFont)
end

function Interface:drawContent()
    -- draw the children
    for _, child in ipairs(self.children) do
        child:draw()
    end

    -- draw attached element
    if self.attached then
        lg.setScissor(self.x,self.y,self.w,self.h)
        self.attached:draw(self.x,self.y,self.w,self.h)
        lg.setScissor()
    end

    -- then draw the content if it exists
    if not self.content then return end
    local m = self.margin

    -- if content is a string, then print it and wrap it
    if type(self.content) == "string" then
        lg.setScissor(self.x,self.y,self.w,self.h)
        lg.printf(self.content, self.x + m, self.y + m, self.w - m*2, self.align)
        lg.setScissor()
    end

    -- if content is an image, then draw it to fill the rect
    if type(self.content) == "userdata" and self.content.typeOf and self.content:typeOf("Image") then
        local sx,sy = self.w/self.content:getWidth(), self.h/self.content:getHeight()
        lg.draw(self.content, self.x,self.y, 0, sx,sy)
    end
end
