TitleScene = class()

local bg = lg.newImage("assets/sprites/title_small_outline.png")
local font = lg.newFont("assets/comicneuebold.ttf", 64)
local smallfont = lg.newFont("assets/comicneuebold.ttf", 48)
local tinyfont = lg.newFont("assets/comicneuebold.ttf", 24)
local music = audio.newMusic("assets/music/title.mp3", 0.35)
local time = 0

local ui = Interface(1024/2 - 125, 768/2 - 200, 250,400)
ui:cut("top", 40):setContent("1")
ui:cut("top", 40):setContent("2")
ui:cut("top", 40):setContent("3")
ui:cut("top", 40):setContent("4")
ui:cut("top", 40):setContent("5")
ui:cut("top", 40):setContent("6")
--ui.content = "this is an interface!!!!! this is an interface! this is so epiccc!! oh my god!"
--ui.content = lg.newImage("assets/sprites/lad.png")

-- quick fix for the game being a little loud
love.audio.setVolume(0.8)

function TitleScene:init()
    --music:play()
end

function TitleScene:update()
    if input.isReleased("shoot") then
        scene(GameScene())
    end
    time = time + 0.05
end

local function drawtext(str,dx,dy)
    colors.black()
    lg.print(str, dx,dy)
end

function TitleScene:draw()
    lg.draw(bg)
    lg.setFont(font)

    ui:draw()

    lg.setFont(smallfont)
    drawtext("Click to start!", 100, 150 + math.sin(time)*4)
    lg.setFont(tinyfont)
    drawtext("Created by groverburger for Ludum Dare 48 in 48 hours\n@grover_burger on Twitter", 64,768-70)
end
