-- pinwheel engine by groverburger
--
-- main.lua should contain only game-specific code
-- the engine should contain all abstracted out game agnostic boilerplate

local path = ...
local pausedAudio = {}
local debugtools

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

return function (settings)
    --------------------------------------------------------------------------------
    -- basic setup
    --------------------------------------------------------------------------------

    -- make the debug console work correctly on windows
    io.stdout:setvbuf("no")
    lg = love.graphics
    lg.setDefaultFilter("nearest")
    local accumulator = 0
    local frametime = settings.frametime or 1/60
    local rollingAverage = {}
    local canvas = {lg.newCanvas(settings.gamewidth, settings.gameheight), depth = true}

    --------------------------------------------------------------------------------
    -- initialize engine
    --------------------------------------------------------------------------------
    -- settings:
    --   gamewidth: int
    --   gameheight: int
    --   debug: bool
    --   frametime: int
    --   web: bool
    --   postprocessing: shader

    engine = {
        settings = settings or {},
        shake = 0,
        shakeSize = 1,
        path = path,
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
    json = require(path .. "/json")
    scene = require(path .. "/scene")
    input = require(path .. "/input")
    colors = require(path .. "/colors")
    audio = require(path .. "/audio")

    -- load the components of the game
    requireAll("things")
    requireAll("scenes")
    requireAll("misc")

    -- optionally load in debugtools, make sure disable for release!
    debugtools = settings.debug and require(path .. "/debugtools")

    -- hijack love.run with a better one
    return function ()
        if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
        if debugtools then debugtools.load(arg) end

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

                    -- debugtools gets priority
                    if not (debugtools and debugtools[name] and debugtools[name](a,b,c,d,e,f)) then
                        love.handlers[name](a,b,c,d,e,f)
                    end

                    -- resize the canvas according to engine settings
                    local fixedCanvas = engine.settings.gamewidth or engine.settings.gameheight
                    if name == "resize" and not fixedCanvas then
                        love.timer.step()
                        canvas[1] = lg.newCanvas()
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

                    -- so input can use mouse wheel as button presses
                    if name == "wheelmoved" then
                        input.mouse.scroll = b
                    end

                    -- only attach virtual mouse to real mouse when real mouse is moved
                    -- so controllers can also move the virtual mouse
                    if name == "mousemoved" then
                        input.updateMouse()
                    end
                end
            end

            -- don't update or draw when game window is not focused
            if love.window.hasFocus() and lg.isActive() then
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
                    accumulator = accumulator - frametime
                    engine.shake = math.max(engine.shake - 1, 0)
                    iter = iter + 1
                    updated = true

                    -- only update input if not in debug console
                    if not (debugtools and debugtools.update()) then input.update() end

                    -- update the game
                    if love.update then love.update() end

                    -- draw the game to a canvas,
                    -- then draw the canvas scaled on the screen
                    lg.origin()
                    lg.clear(0,0,0,0)
                    lg.setCanvas(canvas)
                    lg.clear(lg.getBackgroundColor())
                    if love.draw then love.draw() end
                    lg.setColor(1,1,1)
                    lg.setCanvas()
                    lg.setShader(engine.settings.postprocessing)
                    local screenSize = math.min(lg.getWidth()/canvas[1]:getWidth(), lg.getHeight()/canvas[1]:getHeight())
                    local shake = engine.shake
                    local shakeSize = engine.shakeSize
                    local shakex = shake > 0 and math.sin(math.random()*2*math.pi)*shakeSize*screenSize or 0
                    local shakey = shake > 0 and math.sin(math.random()*2*math.pi)*shakeSize*screenSize or 0
                    lg.draw(canvas[1], lg.getWidth()/2 + shakex, lg.getHeight()/2 + shakey, 0, screenSize, screenSize, canvas[1]:getWidth()/2, canvas[1]:getHeight()/2)
                    lg.setShader()
                    if debugtools then debugtools.draw() end
                    input.mouse.scroll = 0
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
