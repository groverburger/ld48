require "things/thing"

Boom = class(Thing)
Boom.sprite = utils.newAnimation("assets/sprites/boom.png")

local anim = {1,2,3, speed=0.4}

function Boom:new(...)
    Boom.super.new(self, ...)
    self.size = utils.lerp(0.75,2,math.random())
    self.wait = Alarm():set(utils.randomRange(0,8))
end

function Boom:update()
    self.wait:update()
    if self.wait:isActive() then return end
    Boom.super.update(self)
    self:animate(anim)
    self.dead = self.dead or self.animTimer > #anim
end

function Boom:draw()
    if self.wait:isActive() then return end
    if self.sprite and not self.dead then
        self:subdraw(nil,nil,nil,self.size,self.size)
    end
end
