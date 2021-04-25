require "things/enemy"

Bat = class(Enemy)
Bat.sprite = utils.newAnimation("assets/sprites/bat.png")

local idleAnim = {1,2, speed=0.025}

function Bat:new(x,y)
    Bat.super.new(self,x,y)
    self.hoverTime = x*y + x + y
end

function Bat:update()
    Bat.super.update(self)
    self:animate(idleAnim)
    self.y = self.y + math.sin(self.hoverTime)*1.2
    self.hoverTime = self.hoverTime + 0.05
end

function Bat:draw()
    local scene = scenemanager.get()
    local dir = scene.player.x < self.x and -1 or 1

    self:subdraw(nil,nil,nil,dir,nil)
end
