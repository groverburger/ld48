require "things/enemies/enemy"

StillStar = class(Enemy)
StillStar.sprite = utils.newAnimation("assets/sprites/star2.png")

local anim = {1,2}

local function shoot(self)
    self.alarms.shoot:set(60)
    if not self:isLevelActive() then return end

    local scene = scenemanager.get()
    local player = scene.player
    local angle = utils.angle(self.x, self.y, player.x, player.y)
    --self:createThing(Bullet(self.x,self.y,angle,self,15,25))
end

function StillStar:new(x,y)
    StillStar.super.new(self, x+32,y+32)
    self.rot = math.random()*4
    self.hp = 8

    self.alarms = {
        shoot = Alarm(shoot, self):set((x*y + x + y)%60),
    }
end

function StillStar:update()
    StillStar.super.update(self)

    self.rot = (self.rot + 0.1)%(math.pi*2)

    self:animate(anim)
end

function StillStar:draw()
    self:drawKey()
    self:subdraw(nil,nil,nil,nil,nil,self.rot)
end
