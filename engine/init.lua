local path = ...

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

    function engine.getInterpolation()
        return accumulator / frametime
    end

    function engine.resetFramerateSmoothing()
        rollingAverage = {}
    end

    --------------------------------------------------------------------------------
    -- load modules
    --------------------------------------------------------------------------------

    -- make some useful libraries globally scoped
    lume = require(path .. "/lume")
    inspect = require(path .. "/inspect")
    class = require(path .. "/oops")
    utils = require(path .. "/utils")
    Alarm = require(path .. "/alarm")
    json = require(path .. "/json")
    scenemanager = require(path .. "/scenemanager")
    input = require(path .. "/input")
    colors = require(path .. "/colors")

    -- load the components of the game
    utils.requireAll("things")
    utils.requireAll("scenes")
    utils.requireAll("cutscenes")

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
                        canvas = lg.newCanvas()
                    end
                end
            end

            -- don't update or draw when game window is not focused
            if love.window.hasFocus() then
                --------------------------------------------------------------------------------
                -- update
                --------------------------------------------------------------------------------

                -- smooth out the delta time
                table.insert(rollingAverage, love.timer.step())
                if #rollingAverage > 60 then
                    table.remove(rollingAverage, 1)
                end
                local avg = 0
                for i,v in ipairs(rollingAverage) do
                    avg = avg + v
                end

                -- fixed timestep
                accumulator = accumulator + avg/#rollingAverage
                local iter = 0
                while accumulator > frametime and iter < 5 do
                    input.update()
                    engine.shake = math.max(engine.shake - 1, 0)
                    accumulator = accumulator - frametime
                    iter = iter + 1
                    if love.update then love.update() end
                end
                accumulator = accumulator % frametime

                --------------------------------------------------------------------------------
                -- draw
                --------------------------------------------------------------------------------

                -- render the game onto a canvas
                if love.graphics and love.graphics.isActive() then
                    -- set the canvas
                    lg.origin()
                    lg.clear(0,0,0,0)
                    lg.setCanvas(canvas)
                    lg.clear(love.graphics.getBackgroundColor())

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

                    lg.present()
                end

                love.timer.sleep(0.001)
            else
                love.timer.step()
                love.timer.sleep(0.05)
            end
        end
    end
end
