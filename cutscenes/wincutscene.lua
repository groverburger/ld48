require "cutscenes/cutscene"

WinCutscene = class(Cutscene)

local music = audio.newMusic("assets/music/win.mp3")

function WinCutscene:new(throne)
    WinCutscene.super.new(self)

    love.audio.stop()
    music:play()

    local function draw(...)
        table.insert(self.drawcalls, {...})
    end

    self.routine = coroutine.create(function ()
        local scene = scene()
        local player = scene.player
        local i = 0
        scene.cameraTracking = false

        while i < 200 do
            i = i + 1
            scene:pauseFrame()
            player.x = utils.lerp(player.x, throne.x, 0.025)
            player.y = utils.lerp(player.y, throne.y, 0.025)
            scene.camera.x = utils.lerp(scene.camera.x, player.x, 0.1)
            scene.camera.y = utils.lerp(scene.camera.y, player.y, 0.1)
            player.speed.x = 0
            player.speed.y = 0
            player.stretch.x = 1
            player.stretch.y = 1

            if i > 30 then
                local str = "you win!"
                draw(colors.white,utils.map(i, 30,60, 0,1, true))
                draw(lg.print, str, 1024/2 - lg.getFont():getWidth(str)/2, 768/2 - 100)
            end

            coroutine.yield()
        end

        while true do
            i = i + 1
            scene:pauseFrame()

            draw(colors.black, utils.map(i, 200,260, 0,1, true))
            draw(lg.rectangle, "fill", 0, 0, 1024, 768)
            local str = "created by groverburger (zach b)"
            draw(colors.white)
            draw(lg.print, str, 1024/2 - lg.getFont():getWidth(str)/2, 768/2 - 100)

            local str = "music by juhani junkala (opengameart.org)"
            draw(lg.print, str, 1024/2 - lg.getFont():getWidth(str)/2, 768/2)

            local str = "thanks for playing!"
            draw(lg.print, str, 1024/2 - lg.getFont():getWidth(str)/2, 768/2 + 100)

            coroutine.yield()
        end
    end)
end
