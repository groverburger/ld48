TitleScene = class()

local bg = lg.newImage("assets/sprites/title_small_outline.png")
local font = lg.newFont("assets/comicneuebold.ttf", 64)
local smallfont = lg.newFont("assets/comicneuebold.ttf", 48)
local tinyfont = lg.newFont("assets/comicneuebold.ttf", 24)
local music = audio.newMusic("assets/music/title.mp3", 0.35)
local time = 0

local showMenu = true
local closeMenu = function ()
    showMenu = false
end
local w, h = 400, 270
local menu = Interface(1024/2 - w/2, 768/2 - h/2, w, h)
menu:cut("bottom", 36)
    :undercut("left", 140)
    :undercut("right", 140)
    :setContent("accept")
    :setAlign("center")
    :attach(GuiButton(closeMenu))
    :showBorder()
menu:cut("top", 70)
    :setContent("audio settings")
    :setAlign("center")
    :setMargin(10)
local label = menu:cut("left", 200)
h = 32
label:cut("top", h):setContent("master volume:")
menu:cut("top", h):attach(GuiSlider())
menu:cut("top", 16)
label:cut("top", 16)
label:cut("top", h):setContent("music volume:")
menu:cut("top", h):attach(GuiSlider())
menu:cut("top", 16)
label:cut("top", 16)
label:cut("top", h):setContent("sound volume:")
menu:cut("top", h):attach(GuiSlider())

-- quick fix for the game being a little loud
love.audio.setVolume(0.8)

function TitleScene:init()
    --music:play()
end

function TitleScene:update()
    --[[
    if input.isReleased("shoot") then
        scene(GameScene())
    end
    ]]
    time = time + 0.05
end

local function drawtext(str,dx,dy)
    colors.black()
    lg.print(str, dx,dy)
end

function TitleScene:draw()
    lg.draw(bg)
    lg.setFont(font)

    if showMenu then
        menu:draw()
    end

    lg.setFont(smallfont)
    drawtext("Click to start!", 100, 150 + math.sin(time)*4)
    lg.setFont(tinyfont)
    drawtext("Created by groverburger for Ludum Dare 48 in 48 hours\n@grover_burger on Twitter", 64,768-70)
end
