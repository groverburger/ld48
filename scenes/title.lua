TitleScene = class()

local bg = lg.newImage("assets/sprites/title_small_outline.png")
local font = lg.newFont("assets/comicneuebold.ttf", 64)
local smallfont = lg.newFont("assets/comicneuebold.ttf", 48)
local tinyfont = lg.newFont("assets/comicneuebold.ttf", 24)
local music = audio.newMusic("assets/music/title.mp3", 0.35)
local time = 0

local controller = input.controllers.player

local uifont = lg.newFont("assets/comicneuebold.ttf", 20)
local menu, hmenu, hmenuscroll, submenu, scroll, scrollbar

function TitleScene:init()
    menu = GuiForm(1024/2 - 150, 768/2 - 175, 300,350)
        :setBorder(true)
        :setFont(uifont)
    menu:cut("top", 50)
        :setContent("this is a menu")
        :setAlign("center")
        :setMargin(10)

    scroll = menu:cut("top", 250):setBorder(false):setScrollable("down", 200, true)
    --scrollbar = menu:cut("top", 250):setBorder(false)
    --scroll = scrollbar:cut("left", 290):setScrollable("down", 200)
    --scrollbar:attach(GuiScrollbarV(scroll))
    scroll:cut("top", 50):setContent("part 1")
    scroll:cut("top", 50):setContent("part 2")
    scroll:cut("top", 50):setContent("part 3")
    scroll:cut("top", 50):setContent("part 4")
    scroll:cut("top", 50):setContent("part 5")
    scroll:cut("top", 50):setContent("part 6")
    scroll:cut("top", 50):setContent("part 7"):attach(GuiButton(function () print "test" end))
    menu:setContent("footer!")

    hmenu = GuiForm(1024/2 - 100, 768/2 - 100, 200, 200)
        :setBorder(true)
        :setFont(uifont)
    hmenuscroll = hmenu:setScrollable("right", 100, true)
    submenu = hmenuscroll:cut("left", 50):setContent("part 2")
        :setScrollable("down", 200, true)
        :undercut("top", 25)
        :undercut("top", 25)
        :undercut("top", 25)
        :undercut("top", 25)
        :undercut("top", 25)
        :undercut("top", 25)
    submenu:cut("top", 25):setContent "swing your arms from side to side do the mario"
    submenu:undercut("top", 25)
        :undercut("top", 25)
    hmenuscroll:cut("left", 50):setContent("part 1")
    hmenuscroll:cut("left", 50):setContent("part 3")
    hmenuscroll:cut("left", 50):setContent(lg.newImage("assets/sprites/bullet.png"))
    hmenuscroll:cut("left", 50):setContent("part 5")
    hmenuscroll:cut("left", 50):setContent("part 6")

    --music:play()
end

function TitleScene:update()
    if controller:released("shoot") then
        --scene(GameScene())
    end
    time = time + 1
end

local function drawtext(str,dx,dy)
    colors.black()
    lg.print(str, dx,dy)
end

function TitleScene:draw()
    lg.draw(bg)
    lg.setFont(font)

    hmenu:draw()
    --hmenu:setScrollAmount(time/300, nil)
    --scroll:scroll(0,1)
    --submenu:setScrollAmount(nil, time/300)

    lg.setFont(smallfont)
    drawtext("Click to start!", 100, 150 + math.sin(time*0.05)*4)
    lg.setFont(tinyfont)
    drawtext("Created by groverburger for Ludum Dare 48 in 48 hours\n@grover_burger on Twitter", 64,768-70)
end
