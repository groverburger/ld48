local hex = {
    white = "#FFFFFF",
    black = "#000000",
    skyblue = "#A7BFEF",
    blue = "#5959FF",
    red = "#EA2D23",
    yellow = "#FFCC4C",
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
