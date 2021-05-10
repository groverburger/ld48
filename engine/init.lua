-- pinwheel engine by groverburger
--
-- main.lua should contain only game-specific code
-- the engine should contain all abstracted out game agnostic boilerplate

local path = ...

local function requireAll(folder)
    local items = love.filesystem.getDirectoryItems(folder)
    for _, item in ipairs(items) do
        local file = folder .. '/' .. item
        local type = love.filesystem.getInfo(file).type
        if type == "file" then
            require(file:sub(1,-5))
        elseif type == "directory" then
            requireAll(file)
        end
    end
end

local pausedAudio = {}

return function (settings)
    --------------------------------------------------------------------------------
    -- basic setup
    --------------------------------------------------------------------------------

    -- make the debug console work correctly on windows
    io.stdout:setvbuf("no")
    lg = love.graphics
    lg.setDefaultFilter("nearest")
    local accumulator = 0
    local frametime = 1/60
    local rollingAverage = {}
    local canvas = lg.newCanvas(settings.gameWidth, settings.gameHeight)

    --------------------------------------------------------------------------------
    -- initialize engine
    --------------------------------------------------------------------------------

    engine = {
        settings = settings or {},
        shake = 0,
        shakeSize = 1,
    }

    --------------------------------------------------------------------------------
    -- load modules
    --------------------------------------------------------------------------------

    -- make some useful libraries globally scoped
    -- libraries are lowercase, classes are uppercase
    lume = require(path .. "/lume")
    inspect = require(path .. "/inspect")
    class = require(path .. "/oops")
    utils = require(path .. "/utils")
    Alarm = require(path .. "/alarm")
    require(path .. "/rectcut")
    json = require(path .. "/json")
    scene = require(path .. "/scene")
    input = require(path .. "/input")
    colors = require(path .. "/colors")
    audio = require(path .. "/audio")

    -- load the components of the game
    requireAll("things")
    requireAll("scenes")
    requireAll("cutscenes")

    -- pcalls don't work in web, so this automatically
    -- becomes disabled in the release build!
    xpcall(require, print, "engine/debugtools")

    -- hijack love.run with a better one
    return function ()
        if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

        -- don't include load time in timestep
        love.timer.step()

        -- main loop function
        return function()
            -- process events
            if love.event then
                love.event.pump()
                for name, a,b,c,d,e,f in love.event.poll() do
                    if name == "quit" then
                        if not love.quit or not love.quit() then
                            return a or 0
                        end
                    end
                    love.handlers[name](a,b,c,d,e,f)

                    -- resize the canvas according to engine settings
                    local fixedCanvas = engine.settings.gameWidth or engine.settings.gameHeight
                    if name == "resize" and not fixedCanvas then
                        love.timer.step()
                        canvas = lg.newCanvas()
                    end

                    -- pause and unpause audio when the window changes focus
                    if name == "focus" then
                        love.timer.step()
                        if a then
                            for _, v in ipairs(pausedAudio) do v:play() end
                        else
                            pausedAudio = love.audio.pause()
                        end
                    end
                end
            end

            -- don't update or draw when game window is not focused
            if love.window.hasFocus() and lg.isActive() then
                --------------------------------------------------------------------------------
                -- update
                --------------------------------------------------------------------------------

                -- get the delta time
                local delta = love.timer.step()

                -- set some bounds on delta time
                delta = math.min(delta, 0.1)
                delta = math.max(delta, 0.0000001)

                -- fixed timestep
                -- update once, then draw once in a 1:1 ratio, so we don't have to worry about interpolation
                accumulator = accumulator + delta
                local iter = 0
                local updated = false
                while accumulator > frametime and iter < 5 do
                    input.update()
                    engine.shake = math.max(engine.shake - 1, 0)
                    accumulator = accumulator - frametime
                    iter = iter + 1
                    updated = true
                    if love.update then love.update() end

                    -- set the canvas
                    lg.origin()
                    lg.clear(0,0,0,0)
                    lg.setCanvas(canvas)
                    lg.clear(lg.getBackgroundColor())

                    if love.draw then love.draw() end

                    -- render the canvas
                    lg.setColor(1,1,1)
                    lg.setCanvas()
                    local screenSize = math.min(lg.getWidth()/canvas:getWidth(), lg.getHeight()/canvas:getHeight())
                    local shake = engine.shake
                    local shakeSize = engine.shakeSize
                    local shakex = shake > 0 and math.sin(math.random()*2*math.pi)*shakeSize*screenSize or 0
                    local shakey = shake > 0 and math.sin(math.random()*2*math.pi)*shakeSize*screenSize or 0
                    lg.draw(canvas, lg.getWidth()/2 + shakex, lg.getHeight()/2 + shakey, 0, screenSize, screenSize, canvas:getWidth()/2, canvas:getHeight()/2)
                end
                accumulator = accumulator % frametime

                -- only swap buffers if the game updated, to prevent stutter
                if updated then
                    lg.present()
                end

                love.timer.sleep(0.001)
            else
                -- sleep for longer and don't do anything
                -- when the window is not in focus
                love.timer.sleep(0.05)
                love.timer.step()
            end
        end
    end
end
