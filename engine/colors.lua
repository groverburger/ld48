local hex = {
    white = "#FFFFFF",
    black = "#000000",
    blue = "#A7BFEF",
    red = "#EF0C4B",
}

local colors = {}
colors.hex = hex

for color, value in pairs(hex) do
    local r,g,b = lume.color(value)
    colors[color] = function (alpha)
        lg.setColor(r,g,b, alpha or 1)
    end
end

return colors
