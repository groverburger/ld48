GuiButton = class()

function GuiButton:new(callback)
    self.callback = callback
end

function GuiButton:draw(x,y,w,h)
    local hovered = input.mouse.x >= x and input.mouse.y >= y
        and input.mouse.x <= x + w and input.mouse.y <= y + h

    if hovered then
        lg.setColor(1,1,1, 0.25)
        lg.rectangle("fill", x,y,w,h)
        if input.isPressed("leftmouse") then
            self.callback()
        end
    end
end
