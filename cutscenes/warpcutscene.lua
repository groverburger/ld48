WarpCutscene = class()

function WarpCutscene:new()
    self.drawcalls = {}
    local function draw(...)
        table.insert(self.drawcalls, {...})
    end

    self.routine = coroutine.create(function ()
        local scene = scenemanager.get()
        scene.player.currentWarp = nil
        local py = scene.player.y

        for i=1, 60 do
            scene:pauseFrame()
            local value = utils.map(i, 1,60, 0,math.pi/2)
            scene.player.y = py - math.sin(value*2)*200
            scene.depthOffset = value*2/math.pi
            coroutine.yield()
        end

        scene:nextLevel()
    end)
end

function WarpCutscene:update()
    if coroutine.status(self.routine) ~= "dead" then
        lume.clear(self.drawcalls)
        local success, value = coroutine.resume(self.routine)
        assert(success, value)
    else
        self.dead = true
    end
end

function WarpCutscene:draw()
    for _, drawcall in ipairs(self.drawcalls) do
        drawcall[1](drawcall[2], drawcall[3], drawcall[4], drawcall[5], drawcall[6], drawcall[7], drawcall[8])
    end
end
