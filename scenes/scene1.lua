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

function GameScene:new()
    self.camera = {x=0,y=0}
    self.cutscene = nil
    self.depthOffset = 0
    self:setLevel(1)
end

function GameScene:createThing(thing)
    table.insert(self.thingList, thing)
    return thing
end

function GameScene:nextLevel()
    self:setLevel(self.levelIndex + 1)
end

function GameScene:setLevel(index)
    self.levelIndex = index
    self.depthOffset = 0
    local level = self:getLevel()

    -- create all the entities in the list
    self.thingList = {}

    for _, entity in ipairs(level.entities) do
        -- try to get the class from the global table, and make sure it exists
        local class = _G[entity.__identifier]
        if class and type(class) == "table" and class.getClass then
            local instance = class(entity.px[1], entity.px[2])

            -- save a reference to the player
            if class == Player and not self.player then
                self.player = instance
            else
                table.insert(self.thingList, instance)
            end
        else
            print("class " .. entity.__identifier .. " not found!")
        end
    end

    -- add the player if it already exists
    if self.player then
        self.player.spawnPoint.x = self.player.x
        self.player.spawnPoint.y = self.player.y
        table.insert(self.thingList, self.player)
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
        else
            thing:update()
            i = i + 1
        end
    end

    -- camera tracking player and staying centered on level
    local currentLevel = self:getLevel()
    local px, py = self.player.x - 1024/2, self.player.y - 768/2
    local cx, cy = currentLevel.width*64/2 - 1024/2, currentLevel.height*64/2 - 768/2
    self.camera.x = utils.round(utils.lerp(self.camera.x, utils.clamp((px+cx)/2, 0, currentLevel.width*64 - 1024), 0.2))
    self.camera.y = utils.round(utils.lerp(self.camera.y, utils.clamp((py+cy)/2, 0, currentLevel.height*64 - 768), 0.2))
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

function GameScene:draw()
    lg.clear(lume.color(colors.hex.blue))

    local nearestDepth = 1 + 10*self.depthOffset^2
    local furthestLevel = self.levelIndex+3

    -- draw the level and the levels further back
    -- in painter's order
    for i=math.min(furthestLevel, #levels), self.levelIndex, -1 do
        lg.push()

        -- higher depth is closer
        local depth = utils.map(i - self.depthOffset, self.levelIndex, self.levelIndex+10, 1, 0)^2

        if i == self.levelIndex then
            lg.setColor(0,0,0, utils.map(depth, 1,1.035, 1,0))
            depth = nearestDepth
        else
            lg.setColor(utils.colorGradient(depth, "#A7BFEF", "#505B72"))

            if i == self.levelIndex + 1 then
                local r,g,b = lg.getColor()
                r = utils.lerp(r, 0, self.depthOffset)
                g = utils.lerp(g, 0, self.depthOffset)
                b = utils.lerp(b, 0, self.depthOffset)
                lg.setColor(r,g,b)
            end

            if i == furthestLevel then
                local r,g,b = lg.getColor()
                lg.setColor(r,g,b, self.depthOffset)
            end
        end

        lg.translate(-self.camera.x*depth, -self.camera.y*depth)
        local sprite = levels[i].sprite
        lg.translate(480, 4.5*64)
        lg.scale(depth)
        lg.translate(-480, -4.5*64)
        lg.draw(sprite)
        lg.pop()
    end

    -- draw the things in the level
    lg.push()
    lg.translate(640, 7.5*64)
    lg.scale(nearestDepth)
    lg.translate(-640, -7.5*64)
    lg.translate(-self.camera.x, -self.camera.y)
    for i, thing in ipairs(self.thingList) do
        if thing ~= self.player then
            colors.white()
            thing:draw()
        end
    end
    colors.white()
    lg.pop()

    -- draw the player seperately
    -- because the player is not affected by depth
    lg.push()
    lg.translate(-self.camera.x, -self.camera.y)
    if self.player then
        colors.white()
        self.player:draw()
    end
    lg.pop()
end
