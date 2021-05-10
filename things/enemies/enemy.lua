require "things/thing"

Enemy = class(Thing)

local hitShader = lg.newShader("assets/shaders/white.frag")
local deathSound = audio.newSound("assets/sounds/edeath.wav", 0.7)
local hitSound = audio.newSound("assets/sounds/bullethit.wav", 0.5)
local hitSound2 = audio.newSound("assets/sounds/bullethit2.wav", 0.5)

function Enemy:new(x,y)
    Enemy.super.new(self, x,y)
    self.hp = 3
    self.hitflash = 0
end

function Enemy:hit(bullet)
    self.hp = self.hp - 1
    self.hitflash = 4
    utils.choose(hitSound, hitSound2):play()
    love.timer.sleep(0.02)
end

function Enemy:update()
    Enemy.super.update(self)
    self.hitflash = math.max(self.hitflash-1, 0)
    self.dead = self.dead or self.hp <= 0

    if self:isLevelActive() then
        local player = scene().player
        if utils.distance(player.x, player.y, self.x, self.y) <= 40 then
            if player.speed.y > 0.25 then
                self:hit(player)
                player:jump()
            elseif player.speed.y < 0 and player.y < self.y then
                -- let the player jump away from enemies after they've jumped on them
            else
                player:hit(self)
            end
        end
    end
end

function Enemy:collisionAt(x,y)
    return math.abs(x - self.x) <= 32 and math.abs(y - self.y) <= 32
end

function Enemy:onDeath()
    local scene = scene()
    for i, enemy in ipairs(scene.enemyList) do
        if enemy == self then
            table.remove(scene.enemyList, i)
        end
    end

    deathSound:play()
    for i=1, 3 do
        local x, y = utils.lengthdir(math.random()*2*math.pi, utils.randomRange(10,20))
        x, y = x + self.x, y + self.y
        self:createThing(Boom(x,y))
    end

    if self.keycolor then
        local key = Key(self.x,self.y)
        key.keycolor = self.keycolor
        self:createThing(key)
    end
end

function Enemy:drawKey()
    if not self.keycolor then return end

    local r,g,b,a = lg.getColor()
    colors[self.keycolor](a)
    Key.subdraw(Key, self.x+32,self.y+32,1,1,1,0)
    lg.setColor(1,1,1,a)
end

function Enemy:subdraw(...)
    if self.hitflash > 0 then lg.setShader(hitShader) end
    Enemy.super.subdraw(self, ...)
    if self.hitflash > 0 then lg.setShader() end
end

function Enemy:draw()
    self:drawKey()
    Enemy.super.draw(self)
end
