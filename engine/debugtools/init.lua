local path = ...
local console = require(path .. "/console")
local lurker

----------------------------------------------------------------------------------------------------
-- debug hooks
----------------------------------------------------------------------------------------------------

local debugtools = {}

local showMem
function debugtools.load(args)
    lurker = require(path .. "/lurker")

    console:addCommand("showmem", function (args)
        showMem = not showMem
    end)

    console:addCommand("reset", function (args)
        scene(GameScene())
    end)

    console:addCommand("level", function (args)
        scene(GameScene())
        local scene = scene()
        scene:setLevelActive(tonumber(args[2]))

        if args[3] and args[4] then
            local x, y = tonumber(args[3]), tonumber(args[4])
            scene.player.x = x
            scene.player.y = y
            scene.player.spawnPoint.x = x
            scene.player.spawnPoint.y = y
        end
    end)

    -- compile all args into one long string
    local totalArgs = ""
    for i, arg in ipairs(args) do
        totalArgs = totalArgs .. arg .. " "
    end

    -- split totalArgs by semicolon, and pass each as a command to console
    local commandList = lume.split(totalArgs, ",")
    for _, command in ipairs(commandList) do
        console:execute(lume.trim(command))
    end
end

function debugtools.update()
    if lurker then lurker.update() end
    return console:update()
end

function debugtools.draw()
    console:draw(lg.getWidth(), lg.getHeight())
    if showMem then
        lg.setColor(0,0,0)
        lg.print(utils.round(collectgarbage("count")))
    end
end

function debugtools.textinput(text)
    return console:textinput(text)
end

function debugtools.keypressed(k)
    console:keypressed(k)
end

return debugtools
