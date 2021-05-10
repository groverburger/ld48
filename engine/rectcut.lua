Interface = class()

local uifont = lg.newFont(16)

function Interface:new(x,y,w,h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.margin = 4
    self.children = {}
end

function Interface:cut(side, amount)
    local class = self:getClass()

    if side == "right" then
        self.w = self.w - amount
        local n = class(self.x + self.w, self.y, amount, self.h)
        table.insert(self.children, n)
        return n
    end

    if side == "left" then
        self.x = self.x + amount
        self.w = self.w - amount
        local n = class(self.x - amount, self.y, amount, self.h)
        table.insert(self.children, n)
        return n
    end

    if side == "bottom" then
        self.h = self.h - amount
        local n = class(self.x, self.y + self.h, self.w, amount)
        table.insert(self.children, n)
        return n
    end

    if side == "top" then
        self.y = self.y + amount
        self.h = self.h - amount
        local n = class(self.x, self.y - amount, self.w, amount)
        table.insert(self.children, n)
        return n
    end

    error("Interface side " .. side .. " does not exist!")
end

function Interface:setContent(what)
    self.content = what
    return self
end

function Interface:attach(what)
    self.attached = what
    return self
end

function Interface:update()
    if self.attached then
        self.attached:update(self.x,self.y,self.w,self.h)
    end
end

function Interface:draw()
    lg.setColor(0,0,0, 0.75)
    lg.rectangle("fill", self.x,self.y,self.w,self.h)
    lg.setColor(1,1,1)
    lg.rectangle("line", self.x,self.y,self.w,self.h)

    local prevFont = lg.getFont()
    lg.setFont(uifont)
    self:drawContent()
    lg.setFont(prevFont)
end

function Interface:drawContent()
    if not self.content then return end
    local m = self.margin

    -- if content is a string, then print it and wrap it
    if type(self.content) == "string" then
        lg.setScissor(self.x,self.y,self.w,self.h)
        lg.printf(self.content, self.x + m, self.y + m, self.w - m*2)
        lg.setScissor()
    end

    -- if content is an image, then draw it to fill the rect
    if type(self.content) == "userdata" and self.content.typeOf and self.content:typeOf("Image") then
        local sx,sy = self.w/self.content:getWidth(), self.h/self.content:getHeight()
        lg.draw(self.content, self.x,self.y, 0, sx,sy)
    end

    -- also draw the children
    for _, child in ipairs(self.children) do
        child:draw()
    end

    -- draw attached element
    if self.attached then
        lg.setScissor(self.x,self.y,self.w,self.h)
        self.attached:draw()
        lg.setScissor()
    end
end
