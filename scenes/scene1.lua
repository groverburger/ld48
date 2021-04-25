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

            local sb = lg.newSpriteBatch(levelTexture)

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

                    if y == height then
                        sb:add((x-1)*64 - 8, (y)*64 - 8)
                        sb:add((x-1)*64 - 8, (y+1)*64 - 8)
                        sb:add((x-1)*64 - 8, (y+2)*64 - 8)
                        sb:add((x-1)*64 - 8, (y+3)*64 - 8)
                        sb:add((x-1)*64 - 8, (y+4)*64 - 8)
                        sb:add((x-1)*64 - 8, (y+5)*64 - 8)

                        if x == width then
                            for xx=1, 5 do
                                for yy=0, 7 do
                                    sb:add((x+xx)*64 - 8, (y+yy)*64 - 8)
                                end
                            end
                        end

                        if x == 1 then
                            for xx=1, 5 do
                                for yy=0, 7 do
                                    sb:add((x-xx)*64 - 8, (y+yy)*64 - 8)
                                end
                            end
                        end
                    end

                    if x == width then
                        sb:add((x-1)*64 - 8, (y-1)*64 - 8)
                        sb:add((x)*64 - 8, (y-1)*64 - 8)
                        sb:add((x+1)*64 - 8, (y-1)*64 - 8)
                        sb:add((x+2)*64 - 8, (y-1)*64 - 8)
                        sb:add((x+3)*64 - 8, (y-1)*64 - 8)
                        sb:add((x+4)*64 - 8, (y-1)*64 - 8)
                    end

                    if x == 1 then
                        sb:add((x-1)*64 - 8, (y-1)*64 - 8)
                        sb:add((x-2)*64 - 8, (y-1)*64 - 8)
                        sb:add((x-3)*64 - 8, (y-1)*64 - 8)
                        sb:add((x-4)*64 - 8, (y-1)*64 - 8)
                        sb:add((x-5)*64 - 8, (y-1)*64 - 8)
                        sb:add((x-6)*64 - 8, (y-1)*64 - 8)
                    end
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
    self.cameraTracking = true

    self.depthProps = {
        [7] = {
            scale = 10,
            xoff = 0,
            yoff = -500,
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

function GameScene:createThing(thing, levelIndex)
    assert(levelIndex, "no level index given!")
    thing.levelIndex = levelIndex or self.levelIndex
    if not levelIndex or levelIndex == self.levelIndex then
        table.insert(self.thingList, thing)
    else
        table.insert(self.levelThings[levelIndex], thing)
    end

    if thing:instanceOf(Enemy) and levelIndex == self.levelIndex then
        table.insert(self.enemyList, thing)
    end

    if thing.init then
        thing:init()
    end

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
        self.player.levelIndex = self.levelIndex
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

            -- set the instance's level index so it knows what level it's in
            instance.levelIndex = index

            for _, field in ipairs(entity.fieldInstances) do
                if field.__identifier == "message" and class == Text then
                    instance.message = field.__value
                end

                if field.__identifier == "keycolor" then
                    instance.keycolor = field.__value
                end
            end

            -- save a reference to the player
            if class == Player then
                if not self.player then
                    self.player = instance
                end
            else
                table.insert(thingList, instance)

                if instance.init then
                    instance:init()
                end
            end
        else
            print("class " .. entity.__identifier .. " not found!")
        end
    end
end

function GameScene:getLevel(index)
    return levels[index]
end

function GameScene:pauseFrame()
    self.pausedThisFrame = true
end

local neighbors = {1,0,2,-1}

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
    for _, v in pairs(neighbors) do
        local thingList = self.levelThings[self.levelIndex+v]
        if thingList then
            local i = 1
            while i <= #thingList do
                local thing = thingList[i]

                local canupdate = v >= 1 and thing ~= self.player
                canupdate = canupdate or v == 0
                canupdate = canupdate or v == -1 and thing:instanceOf(Bullet)

                if canupdate then
                    if thing.dead then
                        table.remove(thingList, i)
                        if thing.onDeath then
                            thing:onDeath()
                        end
                    else
                        thing:update()
                        i = i + 1
                    end
                else
                    i = i + 1
                end
            end
        end
    end

    -- camera tracking player and staying centered on level
    if self.cameraTracking then
        local currentLevel = self:getLevel(self.levelIndex)
        local px, py = self.player.x, self.player.y
        local cx, cy = currentLevel.width*32, currentLevel.height*32
        self.camera.x = utils.round(utils.lerp(self.camera.x, utils.clamp((px+cx)/2, 1024/2, currentLevel.width*64 - 1024/2), 0.2))
        self.camera.y = utils.round(utils.lerp(self.camera.y, utils.clamp((py+cy)/2, 768/2, currentLevel.height*64 - 768/2), 0.2))
    end
end

local furthest = 20

local function getDepth(i)
    local scene = scenemanager.get()
    return utils.lerp(0.1, 1, utils.map(i - scene.depthOffset, scene.levelIndex, scene.levelIndex+furthest, 1, 0)^5)
end

function GameScene:draw()
    lg.clear(lume.color(colors.hex.skyblue))

    local nearestDepth = 1 + 10*self.depthOffset^2
    local furthestLevel = self.levelIndex+furthest
    local currentLevel = self:getLevel(self.levelIndex)

    -- draw the level and the levels further back
    -- in painter's order
    for i=furthestLevel, math.max(self.levelIndex-1, 1), -1 do
        lg.push()
        colors.white()

        -- higher depth is closer
        local depth = getDepth(i)
        local r,g,b = lume.color("#7D95C4")
        local alpha = 1--utils.map(depth, 0.18,0.2, 0,1)

        if i <= self.levelIndex then
            alpha = utils.map(depth, 1,1.035, 1,0.1)
            colors.white(alpha)
        end

        bgFadeShader:send("bgcolor", {r,g,b,depth^8})
        lg.setShader(bgFadeShader)
        lg.translate(-self.camera.x*depth, -self.camera.y*depth)
        lg.translate(1024/2, 768/2)
        lg.scale(depth)

        if levels[i] then
            local sprite = levels[i].sprite
            colors.white(alpha)
            lg.draw(sprite)
            local things = self.levelThings[i]
            if things and i >= self.levelIndex then
                for _, thing in ipairs(things) do
                    if thing ~= self.player then
                        colors.white(alpha)
                        thing:draw()
                    end
                end
            end
        end

        local prop = self.depthProps[i]
        if prop and i ~= self.levelIndex then
            bgFadeShader:send("bgcolor", {r,g,b,getDepth(i-0.8)^8})
            lg.translate(currentLevel.width*32, currentLevel.height*32)
            local r,g,b = lg.getColor()
            if i == self.levelIndex+1 then
                lg.setColor(r,g,b, utils.map(depth, 0.8,1, 1,0))
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

    local i = 0
    local player = self.player
    for color, _ in pairs(player.keys) do
        colors[color]()
        lg.draw(Key.sprite.source, i*80 + 32, 32)
        i = i + 1
    end
end
