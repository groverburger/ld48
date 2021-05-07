Lock = class(Thing)
Lock.sprite = utils.newAnimation("assets/sprites/lock.png")

local deathSound = soundsystem.newSound("assets/sounds/edeath.wav"):setBaseVolume(0.3)

function Lock:new(x,y)
    Lock.super.new(self, x,y)
end

function Lock:init()
    local scene = scene()
    local level = scene:getLevel(self.levelIndex)
    level[math.floor(self.x/64) + 1][math.floor(self.y/64) + 1] = 1
end

function Lock:update()
    Lock.super.update(self)

    local scene = scene()
    local player = scene.player
    if self:isLevelActive()
    and utils.distance(self.x,self.y, player.x,player.y) <= 100
    and player.keys[self.keycolor] then
        self.dead = true
        --player.keys[self.keycolor] = nil
    end
end

function Lock:onDeath()
    local scene = scene()
    local level = scene:getLevel(self.levelIndex)
    level[math.floor(self.x/64) + 1][math.floor(self.y/64) + 1] = 0

    deathSound:play(utils.randomRange(0.8,1.2))
    for i=1, 3 do
        local x, y = utils.lengthdir(math.random()*2*math.pi, utils.randomRange(10,20))
        x, y = x + self.x, y + self.y
        self:createThing(Boom(x+32,y+32))
    end
end

function Lock:draw()
    local r,g,b,a = lg.getColor()
    colors[self.keycolor](a)
    self:subdraw(self.x + 32, self.y + 32)
end
