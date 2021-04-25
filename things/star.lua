Star = class(Enemy)
Star.sprite = utils.newAnimation("assets/sprites/star.png")

local anim = {1,2}

local function shoot(self)
    self.alarms.shoot:set(60)
    if not self:isLevelActive() then return end

    local scene = scenemanager.get()
    local player = scene.player
    local angle = utils.angle(self.x, self.y, player.x, player.y)
    --scene:createThing(Bullet(self.x,self.y,angle,self,15,25))
end

function Star:new(x,y)
    Star.super.new(self, x,y)
    local spd = 3
    self.speed.x = x%128 == 0 and spd or -spd
    self.speed.y = y%128 == 0 and spd or -spd
    self.rot = math.random()*4

    self.alarms = {
        shoot = Alarm(shoot, self):set((x*y + x + y)%60),
    }
end

function Star:update()
    Star.super.update(self)

    local scene = scenemanager.get()
    if self:isSolid(self.x + self.speed.x, self.y, true,true,true) then
        self.speed.x = self.speed.x * -1
    end
    self.x = self.x + self.speed.x

    if self:isSolid(self.x, self.y + self.speed.y, true,true,true) then
        self.speed.y = self.speed.y * -1
    end
    self.y = self.y + self.speed.y

    self.rot = (self.rot + 0.1)%(math.pi*2)

    self:animate(anim)
end

function Star:draw()
    self:subdraw(nil,nil,nil,nil,nil,self.rot)
end
