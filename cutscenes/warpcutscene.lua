WarpCutscene = class()

function WarpCutscene:new()
    self.drawcalls = {}
    local function draw(...)
        table.insert(self.drawcalls, {...})
    end

    self.routine = coroutine.create(function ()
        local scene = scenemanager.get()
        local player = scene.player
        player.currentWarp = nil
        player.stretch.x = 1
        player.stretch.y = 1
        player.speed.x = 0
        player.speed.y = 15
        player.coyoteFrames = 0
        player.animIndex = 3

        local py = player.y
        local time = 80
        local jumpHeight = 180
        for i=1, time do
            scene:pauseFrame()
            local value = utils.map(i, 1,time, 0,1)

            if i <= time/4 then
                player.y = py - (1-utils.map(i, 1,time/4, 1,0)^2)*jumpHeight
            end
            if i >= time*3/4 then
                player.y = py - (1-utils.map(i, time*3/4,time, 0,1)^2)*jumpHeight
            end

            scene.depthOffset = math.sin(utils.map(value, 0.25, 0.75, 0, math.pi/2, true))
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