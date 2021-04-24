local console = require(... .. "/console")
local lurker = require(... .. "/lurker")

----------------------------------------------------------------------------------------------------
-- debug hooks
----------------------------------------------------------------------------------------------------

local hooks = {}

local totalArgs = ""
local showMem
local paused = false
function hooks.pre_load(args)
    console:addCommand("showmem", function (args)
        showMem = not showMem
    end)

    console:addCommand("reset", function (args)
        scenemanager.set(GameScene())
    end)

    -- compile all args into one long string
    for i, arg in ipairs(args) do
        totalArgs = totalArgs .. arg
        if i < #arg then
            totalArgs = totalArgs .. " "
        end
    end
end

function hooks.post_load()
    -- split totalArgs by semicolon, and pass each as a command to console
    local commandList = lume.split(totalArgs, ",")
    for _, command in ipairs(commandList) do
        console:execute(lume.trim(command))
    end
end

function hooks.pre_update()
    lurker.update()
    console:update()
end

function hooks.post_draw()
    console:draw()
    if showMem then
        lg.setColor(0,0,0)
        lg.print(utils.round(collectgarbage("count")))
    end
end

function hooks.pre_textinput(text)
    console:textinput(text)
end

function hooks.pre_keypressed(k)
    if k == "escape" and not console.enabled then
        love.event.push("quit")
    end

    if not console:keypressed(k) then
        if k == "p" then
            paused = not paused
        end
    end
end

----------------------------------------------------------------------------------------------------
-- love hijacking
----------------------------------------------------------------------------------------------------
-- hijack the love callback functions
-- in order to call a debug hook before they're called

local hijack = {
    "load",
    "update",
    "draw",
    "keypressed",
    "mousepressed",
    "textinput"
}

local loveRefs = {}
for _, key in ipairs(hijack) do
    loveRefs[key] = love[key]

    love[key] = function(...)
        local hijackedArgument
        if hooks["pre_" .. key] then
            hijackedArgument = hooks["pre_" .. key](...)
        end
        if loveRefs[key] then
            loveRefs[key](hijackedArgument or ...)
        end
        if hooks["post_" .. key] then
            hooks["post_" .. key](...)
        end
    end
end
