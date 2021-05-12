TitleScene = class()

local bg = lg.newImage("assets/sprites/title_small_outline.png")
local font = lg.newFont("assets/comicneuebold.ttf", 64)
local smallfont = lg.newFont("assets/comicneuebold.ttf", 48)
local tinyfont = lg.newFont("assets/comicneuebold.ttf", 24)
local music = audio.newMusic("assets/music/title.mp3", 0.35)
local time = 0

local controller = input.controllers.player

local uifont = lg.newFont("assets/comicneuebold.ttf", 20)
local menu, hmenu, submenu

function TitleScene:init()
    menu = GuiForm(1024/2 - 100, 768/2 - 110, 200,210)
        :setScrollable("down", 200)
        :setBorder(true)
        :setFont(uifont)
    menu:cut("top", 50):setContent("part 1")
    menu:cut("top", 50):setContent("part 2")
    menu:cut("top", 50):setContent("part 3")
    menu:cut("top", 50):setContent("part 4")
    menu:cut("top", 50):setContent("part 5")
    menu:cut("top", 50):setContent("part 6")
    menu:cut("top", 50):setContent("part 7"):attach(GuiButton(function () print "test" end))

    hmenu = GuiForm(1024/2 - 100, 768/2 - 100, 200, 200)
        --:setScrollable("right", 200)
        :setBorder(true)
        :setFont(uifont)
    submenu = hmenu:cut("left", 50):setContent("part 2")
        :setScrollable("down", 200)
        :undercut("top", 25)
        :undercut("top", 25)
        :undercut("top", 25)
        :undercut("top", 25)
        :undercut("top", 25)
        :undercut("top", 25)
        :undercut("top", 25)
        :undercut("top", 25)
        :undercut("top", 25)
    hmenu:cut("left", 50):setContent("part 1")
    hmenu:cut("left", 50):setContent("part 3")
    hmenu:cut("left", 50):setContent(lg.newImage("assets/sprites/bullet.png"))
    --hmenu:cut("left", 50):setContent("part 5")
    --hmenu:cut("left", 50):setContent("part 6")

    --music:play()
end

function TitleScene:update()
    if controller:released("shoot") then
        --scene(GameScene())
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

    hmenu:draw()
    --hmenu:scroll(1,0)
    menu:scroll(0,1)
    submenu:scroll(0,0.75)

    lg.setFont(smallfont)
    drawtext("Click to start!", 100, 150 + math.sin(time)*4)
    lg.setFont(tinyfont)
    drawtext("Created by groverburger for Ludum Dare 48 in 48 hours\n@grover_burger on Twitter", 64,768-70)
end
