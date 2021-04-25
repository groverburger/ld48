require "things/thing"

Enemy = class(Thing)

local hitShader = lg.newShader("assets/shaders/white.frag")

function Enemy:new(x,y)
    Enemy.super.new(self, x,y)
    local scene = scenemanager.get()
    table.insert(scene.enemyList, self)
    self.hp = 3
    self.hitflash = 0
end

function Enemy:hit(bullet)
    self.hp = self.hp - 1
    self.hitflash = 4
    love.timer.sleep(0.02)
end

function Enemy:update()
    Enemy.super.update(self)
    self.hitflash = math.max(self.hitflash-1, 0)
    self.dead = self.dead or self.hp <= 0
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
end

function Enemy:subdraw(...)
    if self.hitflash > 0 then lg.setShader(hitShader) end
    Enemy.super.subdraw(self, ...)
    lg.setShader()
end
