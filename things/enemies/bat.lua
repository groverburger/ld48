require "things/enemies/enemy"

local batfly = audio.newSound("assets/sounds/batfly.wav")

Bat = class(Enemy)
Bat.sprite = utils.newAnimation("assets/sprites/bat.png")
Bat.animIndex = 3
Bat.state = 1

local anims = {
    {3,4},
    {1,2, speed=0.075},
}

function Bat:new(x,y)
    Bat.super.new(self,x+32,y+48)
    self.hoverTime = 0
    self.oy = y+48
    self.alarms = {
        wakeup = Alarm(),
    }
end

function Bat:hit()
    Bat.super.hit(self)

    if self.state == 1 then
        self.state = 2
        self.alarms.wakeup:set(60)
        batfly:play()
    end
end

function Bat:update()
    Bat.super.update(self)

    self:animate(anims[self.state])
    if self.alarms.wakeup:isActive() then
        local p = self.alarms.wakeup:getProgress()
        if p < 0.8 then
            self.y = self.oy + utils.map((1-p)^2, 1,0, 0,150)
            return
        end
    end

    local scene = scene()
    local player = scene.player
    if self.state == 1 then
        if math.abs(player.x-self.x) < 250
        and player.y > self.y + 64
        and self:isLevelActive() then
            self.state = 2
            self.alarms.wakeup:set(60)
            batfly:play()
        end
    elseif utils.distance(self.x,self.y,player.x,player.y) > 24 then
        local angle = utils.angle(self.x,self.y,player.x,player.y)
        self.speed.x, self.speed.y = utils.lengthdir(angle, 1.5)
        self.speed.y = self.speed.y + math.sin(self.hoverTime)*1.2
        self.hoverTime = self.hoverTime + 0.05

        if not self:isSolid(self.x + self.speed.x, self.y, true, true, true) then
            self.x = self.x + self.speed.x
        end

        if not self:isSolid(self.x, self.y + self.speed.y, true, true, true) then
            self.y = self.y + self.speed.y
        end
    end
end

function Bat:draw()
    local scene = scene()
    local dir = self.state == 2 and scene.player.x < self.x and -1 or 1

    self:drawKey()
    self:subdraw(nil,nil,nil,dir,nil)
end
