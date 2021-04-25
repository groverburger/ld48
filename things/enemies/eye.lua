require "things/enemies/enemy"

Eye = class(Enemy)
Eye.sprite = utils.newAnimation("assets/sprites/eye.png")

local anim = {1,2}

local function shoot(self)
    self.alarms.shoot:reset()
    self.alarms.blink:set(8)
    local scene = scenemanager.get()
    local angle = math.acos(self.xdir)
    local bullet = self:createThing(Bullet(self.x + self.xdir*32,self.y,angle,self,15,70))
end

function Eye:new(x,y)
    Eye.super.new(self, x + 32, y + 32)

    self.alarms = {
        shoot = Alarm(shoot, self):set(60),
        blink = Alarm(),
    }
end

function Eye:init()
    self.xdir = self:isSolid(self.x+64, self.y, true,true,true) and -1 or 1
    self.x = self.x + self.xdir*48
end

function Eye:update()
    Eye.super.update(self)
    self.animIndex = self.alarms.blink:isActive() and 2 or 1
end

function Eye:draw()
    self:drawKey()
    self:subdraw(nil,nil,nil,self.xdir*1.2,1.2)
end
