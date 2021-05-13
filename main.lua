love.window.setIcon(love.image.newImageData("assets/sprites/gameicon.png"))

love.run = require "engine" {
    gamewidth = 1024,
    gameheight = 768,
    debug = true,
    --postprocessing = love.graphics.newShader("assets/shaders/pixelscale.frag")
}

local showPauseMenu, showAudioMenu, paused
local pauseMenu, audioMenu
local volumes = {}

local uifont = lg.newFont("assets/comicneuebold.ttf", 20)

input.newController("menu", {controls = {ok = {"mouse:left"}, scrolldown = {"mouse:wd"}, scrollup = {"mouse:wu"}}})
local button = "ok"
local controller = "menu"

pauseMenu = GuiForm(1024/2 - 250/2, 768/2 - 200/2, 250, 300):setFont(uifont)
pauseMenu:cut("top", 70)
    :setContent("paused")
    :setAlign("center")
    :setMargin(10)
pauseMenu:cut("top", 36)
    :undercut("left", 20)
    :undercut("right", 20)
    :attach(GuiButton(function() showAudioMenu = true; showPauseMenu = false end))
    :setContent("audio settings")
    :setAlign("center")
    :setBorder(true)
pauseMenu:cut("top", 20)
pauseMenu:cut("top", 36)
    :undercut("left", 20)
    :undercut("right", 20)
    :attach(GuiButton(function() love.event.push("quit") end))
    :setContent("quit game")
    :setAlign("center")
    :setBorder(true)
pauseMenu:cut("bottom", 16)
pauseMenu:cut("bottom", 36)
    :undercut("left", 65)
    :undercut("right", 65)
    :setContent("resume")
    :setAlign("center")
    :attach(GuiButton(function() showPauseMenu = false; paused = false end))
    :setBorder(true)

audioMenu = GuiForm(1024/2 - 400/2, 768/2 - 270/2, 400, 270):setFont(uifont)
audioMenu:cut("bottom", 36)
    :undercut("left", 140)
    :undercut("right", 140)
    :setContent("ok")
    :setAlign("center")
    :attach(GuiButton(function() showAudioMenu = false; showPauseMenu = true end))
    :setBorder(true)
audioMenu:cut("top", 70)
    :setContent("audio settings")
    :setAlign("center")
    :setMargin(10)
local label = audioMenu:cut("left", 200)
local h = 32
label:cut("top", h):setContent("master volume:")
audioMenu:cut("top", h):attach(GuiSlider(volumes, "master", 1))
audioMenu:cut("top", 16)
label:cut("top", 16)
label:cut("top", h):setContent("music volume:")
audioMenu:cut("top", h):attach(GuiSlider(volumes, "music", 1))
audioMenu:cut("top", 16)
label:cut("top", 16)
label:cut("top", h):setContent("sound volume:")
audioMenu:cut("top", h):attach(GuiSlider(volumes, "sound", 1))

function love.load(args)
    --engine.settings.postprocessing:send("width", 1024)
    --engine.settings.postprocessing:send("height", 768)
    --engine.settings.postprocessing:send("uvmod", 1)
    scene(TitleScene())
end

function love.update()
    local scene = scene()
    if scene.update and not paused then
        scene:update()
    end

    if love.keyboard.isDown("escape") then
        paused = true
        showPauseMenu = true
    end
end

function love.draw()
    local scene = scene()
    if scene.draw then
        scene:draw()
    end

    if showPauseMenu then
        pauseMenu:draw()
    end
    if showAudioMenu then
        audioMenu:draw()

        love.audio.setVolume(volumes.master and volumes.master^2 or 1)
        audio.setSoundVolume(volumes.sound and volumes.sound^2 or 1)
        audio.setMusicVolume(volumes.music and volumes.music^2 or 1)
    end
end

