require "things/thing"

Bullet = class(Thing)
Bullet.sprite = utils.newAnimation("assets/sprites/bullet.png")
local sound = soundsystem.newSound("assets/sounds/gun1.wav"):setBaseVolume(0.7)
local colSound = soundsystem.newSound("assets/sounds/bulletCol.wav"):setBaseVolume(0.2)

function Bullet:new(x,y,angle)
    Bullet.super.new(self, x,y)

    self.speed.mag = 30
    self.speed.x, self.speed.y = utils.lengthdir(angle, self.speed.mag)
    self.life = Alarm():set(18)
    self.animIndex = 0
    self.size = 1

    sound:play(utils.randomRange(0.8,1.2))
end

function Bullet:update()
    local scene = scenemanager.get()
    self.x = self.x + self.speed.x
    self.y = self.y + self.speed.y

    for i=1, self.speed.mag, 2 do
        local angle = utils.angle(0,0,self.speed.x,self.speed.y)
        local hit = scene:isSolid(self.x + math.cos(angle)*i, self.y + math.sin(angle)*i)
        if hit and not self.dead then
            colSound:play()
            scene:createThing(Impact(self.x,self.y))
        end
        self.dead = self.dead or hit
    end

    self.life:update()
    self.dead = self.dead or not self.life:isActive()

    if self.animIndex == 0 then
        self.animIndex = 1
    else
        self.animIndex = 2
    end
end

function Bullet:subdraw(x, y, frame)
    lg.draw(self.sprite.source, self.sprite[frame or self.animIndex], x or self.x, y or self.y, 0, self.size, self.size, self.sprite.size/2, self.sprite.size/2)
end

function Bullet:draw()
    if self.animIndex == 0 then self.animIndex = 1 end

    self.size = 1
    if self.animIndex == 2 then
        colors.red()
        self:subdraw(self.x + self.speed.x*-1, self.y + self.speed.y*-1)
        self:subdraw(self.x + self.speed.x*-0.5,  self.y + self.speed.y*-0.5)
        colors.white()
        self:subdraw()
    else
        self.size = 1.5
        self:subdraw()
    end
end
