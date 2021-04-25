WinCutscene = class()

function WinCutscene:new(throne)
    self.drawcalls = {}
    local function draw(...)
        table.insert(self.drawcalls, {...})
    end

    self.routine = coroutine.create(function ()
        local scene = scenemanager.get()
        local player = scene.player
        local i = 0
        scene.cameraTracking = false

        while true do
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
                colors.white(utils.map(i, 30,60, 0,1, true))
                draw(lg.print, str, player.x - lg.getFont():getWidth(str)/2, player.y - 200)
            end

            coroutine.yield()
        end
    end)
end

function WinCutscene:update()
    if coroutine.status(self.routine) ~= "dead" then
        lume.clear(self.drawcalls)
        local success, value = coroutine.resume(self.routine)
        assert(success, value)
    else
        self.dead = true
    end
end

function WinCutscene:draw()
    for _, drawcall in ipairs(self.drawcalls) do
        drawcall[1](drawcall[2], drawcall[3], drawcall[4], drawcall[5], drawcall[6], drawcall[7], drawcall[8])
    end
end
