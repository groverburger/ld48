require "cutscenes/cutscene"

WarpCutscene = class(Cutscene)

local warpSound = audio.newSound("assets/sounds/warp.wav", 1, 1)
local warpStartSound = audio.newSound("assets/sounds/warpstart.wav", 1, 1)

function WarpCutscene:new(warpDir)
    WarpCutscene.super.new(self)

    local function draw(...)
        table.insert(self.drawcalls, {...})
    end

    self.routine = coroutine.create(function ()
        local scene = scene()
        local player = scene.player
        local warpThing = player.currentWarp
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
        warpStartSound:play()
        for i=1, time do
            scene:pauseFrame()
            local value = utils.map(i, 1,time, 0,1)
            player.x = utils.lerp(player.x, warpThing.x, 0.1)

            if i == 20 then
                warpSound:play()
            end

            if i <= time/4 then
                player.y = py - (1-utils.map(i, 1,time/4, 1,0)^2)*jumpHeight
            end
            if i >= time*3/4 then
                player.y = py - (1-utils.map(i, time*3/4,time, 0,1)^2)*jumpHeight
            end

            scene.depthOffset = math.sin(utils.map(value, 0.25, 0.75, 0, math.pi/2, true)) * warpDir
            coroutine.yield()
        end

        player.spawnPoint.x = player.x
        player.spawnPoint.y = player.y

        scene.levelIndex = scene.levelIndex + warpDir
        scene:setLevelActive(scene.levelIndex)
    end)
end
