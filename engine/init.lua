local path = ...

return function (settings)
    -- global engine table
    engine = {}

    engine.settings = settings or {}

    -- make the debug console work correctly on windows
    io.stdout:setvbuf("no")

    lg = love.graphics
    lg.setDefaultFilter("nearest")

    -- make some useful libraries globally scoped
    lume = require(path .. "/lume")
    inspect = require(path .. "/inspect")
    class = require(path .. "/oops")
    utils = require(path .. "/utils")
    Alarm = require(path .. "/alarm")
    json = require(path .. "/json")
    scenemanager = require(path .. "/scenemanager")
    input = require(path .. "/input")

    -- load the components of the game
    utils.requireAll("things")
    utils.requireAll("scenes")
    utils.requireAll("cutscenes")

    local accumulator = 0
    local frametime = 1/60
    local rollingAverage = {}
    local canvas = lg.newCanvas(engine.settings.gameWidth, engine.settings.gameHeight)

    function engine.getInterpolation()
        return accumulator / frametime
    end

    function engine.resetFramerateSmoothing()
        rollingAverage = {}
    end

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
                    lg.setCanvas(canvas)
                    love.graphics.origin()
                    love.graphics.clear(love.graphics.getBackgroundColor())

                    if love.draw then love.draw() end

                    -- render the canvas
                    lg.setColor(1,1,1)
                    lg.setCanvas()
                    local size = math.min(lg.getWidth()/canvas:getWidth(), lg.getHeight()/canvas:getHeight())
                    lg.draw(canvas, lg.getWidth()/2, lg.getHeight()/2, 0, size, size, canvas:getWidth()/2, canvas:getHeight()/2)

                    love.graphics.present()
                end

                love.timer.sleep(0.001)
            else
                love.timer.step()
                love.timer.sleep(0.05)
            end
        end
    end
end
