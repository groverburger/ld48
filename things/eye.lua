Eye = class(Enemy)
Eye.sprite = utils.newAnimation("assets/sprites/eye.png")

local anim = {1,2}

local function shoot(self)
    self.alarms.shoot:reset()
    self.alarms.blink:set(8)
    local scene = scenemanager.get()
    local angle = math.acos(self.xdir)
    scene:createThing(Bullet(self.x + self.xdir*32,self.y,angle,self,15,70))
end

function Eye:new(x,y)
    local scene = scenemanager.get()
    self.xdir = scene:isSolid(x+32, y) and -1 or 1
    Eye.super.new(self, x + (self.xdir == 1 and 48 or 16),y)

    self.alarms = {
        shoot = Alarm(shoot, self):set(60),
        blink = Alarm(),
    }
end

function Eye:update()
    Eye.super.update(self)
    self.animIndex = self.alarms.blink:isActive() and 2 or 1
end

function Eye:draw()
    self:subdraw(nil,nil,nil,self.xdir*1.2,1.2)
end
