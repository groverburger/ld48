TitleScene = class()

local bg = lg.newImage("assets/sprites/title.png")
local font = lg.newFont("assets/comicneuebold.ttf", 64)
local smallfont = lg.newFont("assets/comicneuebold.ttf", 48)
local tinyfont = lg.newFont("assets/comicneuebold.ttf", 24)
local music = soundsystem.newMusic("assets/music/title.mp3", 0.35)
local time = 0

function TitleScene:new()
    music:play()
end

function TitleScene:update()
    if input.isReleased("shoot") then
        music:stop()
        scenemanager.set(GameScene())
    end
    time = time + 0.05
end

local function drawtext(str,dx,dy)
    --[[
    colors.white()
    local r = lg.getFont() == font and 5 or 3
    if lg.getFont() == tinyfont then r = 2 end
    for i=0, math.pi*2, math.pi*2/10 do
        local dx, dy = dx + math.cos(i)*r, dy + math.sin(i)*r
        lg.print(str, dx,dy)
    end
    ]]

    colors.black()
    lg.print(str, dx,dy)
end

function TitleScene:draw()
    lg.draw(bg)
    lg.setFont(font)
    --drawtext("Into the Castle", 64,240)

    lg.setFont(smallfont)
    drawtext("Click to start!", 100, 150 + math.sin(time)*4)
    lg.setFont(tinyfont)
    drawtext("Created by groverburger for Ludum Dare 48 in 48 hours\n@grover_burger on Twitter", 64,768-70)
end
