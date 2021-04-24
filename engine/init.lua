local engine = {}

-- make the debug console work correctly on windows
io.stdout:setvbuf("no")

lg = love.graphics
lg.setDefaultFilter("nearest")

-- make some useful libraries globally scoped
local path = ...
lume = require(path .. "/lume")
inspect = require(path .. "/inspect")
class = require(path .. "/oops")
utils = require(path .. "/utils")
Alarm = require(path .. "/alarm")
json = require(path .. "/json")
scenemanager = require(path .. "/scenemanager")

-- load the components of the game
utils.requireAll("things")
utils.requireAll("scenes")

local accumulator = 0
local frametime = 1/60
local rollingAverage = {}
local scene

function engine.getInterpolation()
    return accumulator / frametime
end

function engine.resetFramerateSmoothing()
    rollingAverage = {}
end

-- hijack love.run with a better one
function love.run(configs)
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
			end
		end

        -- smooth out the delta time
        table.insert(rollingAverage, love.timer.step())
        if #rollingAverage > 60 then
            table.remove(rollingAverage, 1)
        end
        local avg = 0
        for i,v in ipairs(rollingAverage) do
            avg = avg + v
        end

		-- don't update or draw when game window is not focused
        if love.window.hasFocus() then
            -- fixed timestep
            accumulator = accumulator + avg/#rollingAverage
            local iter = 0
            while accumulator > frametime and iter < 10 do
                accumulator = accumulator - frametime
                iter = iter + 1
                if love.update then love.update() end
            end
            accumulator = accumulator % frametime

            -- render the game
            if love.graphics and love.graphics.isActive() then
                love.graphics.origin()
                love.graphics.clear(love.graphics.getBackgroundColor())

                if love.draw then love.draw() end

                love.graphics.present()
            end

            love.timer.sleep(0.001)
        else
            love.timer.sleep(0.05)
        end
	end
end

return engine
