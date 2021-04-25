require "things/thing"

Enemy = class(Thing)

local hitShader = lg.newShader("assets/shaders/white.frag")
local deathSound = soundsystem.newSound("assets/sounds/edeath.wav"):setBaseVolume(0.3)

function Enemy:new(x,y)
    Enemy.super.new(self, x,y)
    self.hp = 3
    self.hitflash = 0
end

function Enemy:hit(bullet)
    self.hp = self.hp - 1
    self.hitflash = 4
    love.timer.sleep(0.03)
end

function Enemy:update()
    Enemy.super.update(self)
    self.hitflash = math.max(self.hitflash-1, 0)
    self.dead = self.dead or self.hp <= 0

    if self:isLevelActive() then
        local player = scenemanager.get().player
        if utils.distance(player.x, player.y, self.x, self.y) <= 40 then
            player:hit(self)
        end
    end
end

function Enemy:collisionAt(x,y)
    return math.abs(x - self.x) <= 32 and math.abs(y - self.y) <= 32
end

function Enemy:onDeath()
    local scene = scenemanager.get()
    for i, enemy in ipairs(scene.enemyList) do
        if enemy == self then
            table.remove(scene.enemyList, i)
        end
    end

    deathSound:play(utils.randomRange(0.8,1.2))
    for i=1, 3 do
        local x, y = utils.lengthdir(math.random()*2*math.pi, utils.randomRange(10,20))
        x, y = x + self.x, y + self.y
        scene:createThing(Boom(x,y))
    end
end

function Enemy:subdraw(...)
    if self.hitflash > 0 then lg.setShader(hitShader) end
    Enemy.super.subdraw(self, ...)
    if self.hitflash > 0 then lg.setShader() end
end
