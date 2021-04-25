require "things/enemies/enemy"

Glasses = class(Enemy)
Glasses.sprite = utils.newAnimation("assets/sprites/glasses.png")

local function shoot(self)
    self.alarms.shoot:set(120)
    if not self:isLevelActive() then return end
    self.alarms.blink:set(20)
    self.alarms.shot1:set(5)
    self.alarms.shot2:set(10)
    self.alarms.shot3:set(15)
end

local function shot(self)
    local scene = scenemanager.get()
    local player = scene.player
    local angle = utils.angle(self.x,self.y,player.x,player.y)
    local bullet = self:createThing(Bullet(self.x,self.y,angle,self,15,70))
end

function Glasses:new(x,y)
    Glasses.super.new(self, x + 32, y + 32)

    self.hp = 5
    self.alarms = {
        shoot = Alarm(shoot, self):set((x*y + x + y)%120),
        shot1 = Alarm(shot, self),
        shot2 = Alarm(shot, self),
        shot3 = Alarm(shot, self),
        blink = Alarm(),
    }
end

function Glasses:init()
    self.xdir = self:isSolid(self.x+64, self.y, true,true,true) and -1 or 1
    self.x = self.x + self.xdir*48
end

function Glasses:update()
    Glasses.super.update(self)
    self.animIndex = self.alarms.blink:isActive() and 2 or 1
end
