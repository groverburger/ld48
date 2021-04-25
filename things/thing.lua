Thing = class()

function Thing:new(x, y)
    self.x = x
    self.y = y
    self.speed = {x=0,y=0}
    self.animIndex = 1
    self.animTimer = 0
    self.levelIndex = 1 -- updated by the scene
end

function Thing:update()
    -- update my alarms
    if self.alarms then
        for _, alarm in pairs(self.alarms) do
            alarm:update()
        end
    end
end

function Thing:draw()
    if self.sprite and not self.dead then
        self:subdraw()
    end
end

function Thing:subdraw(x, y, frame, xs, ys, rot)
    lg.draw(self.sprite.source, self.sprite[frame or math.floor(self.animIndex)], x or self.x, y or self.y, rot or 0, xs or 1, ys or 1, self.sprite.size/2, self.sprite.size/2)
end

function Thing:animate(anim)
    self.animTimer = self.animTimer + (anim.speed or 0.1)
    self.animIndex = anim[math.floor(self.animTimer % #anim) + 1]
end

function Thing:isLevelActive()
    local scene = scenemanager.get()
    return scene.levelIndex == self.levelIndex
end

function Thing:createThing(thing)
    local scene = scenemanager.get()
    return scene:createThing(thing, self.levelIndex)
end

function Thing:isSolid(x,y, tile,hoob,voob)
    local scene = scenemanager.get()
    local level = scene:getLevel(self.levelIndex)

    if hoob and (x <= 0 or x >= level.width*64) then return true end
    if voob and (y <= 0 or y >= level.height*64) then return true end

    if tile then
        local x, y = math.floor(x/64)+1, math.max(math.floor(y/64)+1, 1)
        if level[x] and level[x][y] then
            return level[x][y] == 1
        end
    end

    return false
end
