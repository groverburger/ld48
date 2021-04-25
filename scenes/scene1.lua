GameScene = class()

----------------------------------------------------------------------------------------------------
-- load the game map
----------------------------------------------------------------------------------------------------

local map = json.decode(love.filesystem.read("assets/map.ldtk"))
local levels = {}
local levelTexture = lg.newImage("assets/sprites/tile.png")
for levelIndex, level in ipairs(map.levels) do
    local currentLevel = {}
    levels[levelIndex] = currentLevel

    for _, layer in ipairs(level.layerInstances) do
        if layer.__identifier == "IntGrid" then
            local width, height = layer.__cWid, layer.__cHei

            local sb = lg.newSpriteBatch(levelTexture, width*height)

            -- load the data itself
            currentLevel.width = width
            currentLevel.height = height
            currentLevel.sprite = sb
            for i, v in ipairs(layer.intGridCsv) do
                local x, y = (i-1)%width + 1, math.floor((i-1)/width) + 1
                if not currentLevel[x] then currentLevel[x] = {} end
                currentLevel[x][y] = v

                -- add tiles to the spritebatch
                if v == 1 then
                    sb:add((x-1)*64 - 8, (y-1)*64 - 8)
                end
            end
        end

        if layer.__identifier == "Entities" then
            currentLevel.entities = layer.entityInstances
        end
    end
end

local bgFadeShader = lg.newShader("assets/shaders/bgfade.frag")

function GameScene:new()
    self.camera = {x=640,y=7.5*64}
    self.cutscene = nil
    self.depthOffset = 0
    self.levelThings = {}

    self.depthProps = {
        [2] = {
            scale = 12,
            xoff = 0,
            yoff = -400,
            sprite = lg.newImage("assets/sprites/castle.png"),
        },
    }
end

function GameScene:init()
    self.levelIndex = 1
    for i, level in ipairs(levels) do
        self:loadLevel(i, level)
    end
    self:setLevelActive(1)
end

function GameScene:createThing(thing)
    table.insert(self.thingList, thing)
    return thing
end

function GameScene:nextLevel()
    self.levelIndex = self.levelIndex + 1
    self:setLevelActive(self.levelIndex)
end

function GameScene:resetLevel()
    self:loadLevel(self.levelIndex, levels[self.levelIndex])
    self:setLevelActive(self.levelIndex)
end

function GameScene:setLevelActive(index)
    if self.player and self.levelThings[self.levelIndex] then
        lume.remove(self.levelThings[self.levelIndex], self.player)
    end

    self.levelIndex = index
    self.depthOffset = 0
    self.thingList = self.levelThings[index]

    -- put all the enemies in their own list
    self.enemyList = {}
    for _, thing in ipairs(self.thingList) do
        thing.levelIndex = index
        if thing:instanceOf(Enemy) then
            table.insert(self.enemyList, thing)
        end
    end

    if self.player then
        table.insert(self.thingList, self.player)
    end
end

function GameScene:loadLevel(index, level)
    local thingList = {}
    self.levelThings[index] = thingList

    for _, entity in ipairs(level.entities) do
        -- try to get the class from the global table, and make sure it exists
        local class = _G[entity.__identifier]
        if class and type(class) == "table" and class.getClass then
            local instance = class(entity.px[1], entity.px[2])

            -- set the instance's index so it knows where it is
            instance.levelIndex = index

            -- save a reference to the player
            if class == Player then
                if not self.player then
                    self.player = instance
                end
            else
                table.insert(thingList, instance)
            end
        else
            print("class " .. entity.__identifier .. " not found!")
        end
    end
end

function GameScene:getLevel()
    return levels[self.levelIndex]
end

function GameScene:pauseFrame()
    self.pausedThisFrame = true
end

function GameScene:update()
    if self.cutscene then
        self.cutscene:update()
        if self.cutscene.dead then
            self.cutscene = nil
        end
    end

    if self.pausedThisFrame then
        self.pausedThisFrame = false
        return
    end

    -- update all things in the scene, cull the dead ones
    local i = 1
    while i <= #self.thingList do
        local thing = self.thingList[i]

        if thing.dead then
            table.remove(self.thingList, i)
            if thing.onDeath then
                thing:onDeath()
            end
        else
            thing:update()
            i = i + 1
        end
    end

    local thingList = self.levelThings[self.levelIndex+1]
    if thingList then
        for _, thing in ipairs(thingList) do
            if thing ~= self.player then
                thing:update()
            end
        end
    end

    -- camera tracking player and staying centered on level
    local currentLevel = self:getLevel()
    local px, py = self.player.x, self.player.y
    local cx, cy = currentLevel.width*32, currentLevel.height*32
    self.camera.x = utils.round(utils.lerp(self.camera.x, utils.clamp((px+cx)/2, 1024/2, currentLevel.width*64 - 1024/2), 0.2))
    self.camera.y = utils.round(utils.lerp(self.camera.y, utils.clamp((py+cy)/2, 768/2, currentLevel.height*64 - 768/2), 0.2))
end

function GameScene:isSolid(x,y)
    -- out of bounds horizontally is solid
    if x <= 0 or x >= 20*64 then return true end

    local level = self:getLevel()
    local x, y = math.floor(x/64)+1, math.floor(y/64)+1

    if level[x] and level[x][y] then
        return level[x][y] == 1
    end

    return false
end

function GameScene:isSolidNoOob(x,y)
    local level = self:getLevel()
    local x, y = math.floor(x/64)+1, math.floor(y/64)+1

    if level[x] and level[x][y] then
        return level[x][y] == 1
    end

    return false
end

-- out of bounds
function GameScene:isOob(x,y)
    -- out of bounds horizontally is solid
    if x <= 0 or x >= 20*64 then return true end
    if y <= 0 or y >= 15*64 then return true end

    return false
end

local function getDepth(i)
    local scene = scenemanager.get()
    return utils.map(i - scene.depthOffset, scene.levelIndex, scene.levelIndex+10, 1, 0.05)^5
end

function GameScene:draw()
    lg.clear(lume.color(colors.hex.blue))

    local nearestDepth = 1 + 10*self.depthOffset^2
    local furthestLevel = self.levelIndex+3

    -- draw the level and the levels further back
    -- in painter's order
    for i=math.min(furthestLevel, #levels), math.max(self.levelIndex-1, 1), -1 do
        lg.push()
        colors.white()

        -- higher depth is closer
        local depth = getDepth(i)
        local r,g,b = lume.color("#A7BFEF")

        if i <= self.levelIndex then
            colors.white(utils.map(depth, 1,1.035, 1,0))
        end

        bgFadeShader:send("bgcolor", {r,g,b,depth})
        lg.setShader(bgFadeShader)
        local sprite = levels[i].sprite
        lg.translate(-self.camera.x*depth, -self.camera.y*depth)
        lg.translate(1024/2, 768/2)
        lg.scale(depth)
        lg.draw(sprite)
        for _, thing in ipairs(self.levelThings[i]) do
            if thing ~= self.player then
                thing:draw()
            end
        end

        local prop = self.depthProps[i]
        if prop and i ~= self.levelIndex then
            lg.translate(1024/2, 768/2)
            local r,g,b = lg.getColor()
            if i == self.levelIndex+1 then
                lg.setColor(r,g,b, utils.map(self.depthOffset, 0,1, 1,0))
            end

            lg.draw(prop.sprite, prop.xoff or 0, prop.yoff or 0, 0, prop.scale, prop.scale, prop.sprite:getWidth()/2, prop.sprite:getHeight()/2)
        end

        lg.pop()
        lg.setShader()
    end

    -- draw the player seperately
    -- because the player is not affected by depth
    lg.push()
    lg.translate(-self.camera.x, -self.camera.y)
    lg.translate(1024/2, 768/2)
    if self.player then
        colors.white()
        self.player:draw()
    end
    lg.pop()
end
