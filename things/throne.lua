require "things/thing"

Throne = class(Thing)
Throne.sprite = utils.newAnimation("assets/sprites/throne.png")

function Throne:new(x,y)
    Throne.super.new(self, x+128,y+128)
end

function Throne:init()
    self.king = King(self.x,self.y)
    self:createThing(self.king)
end

function Throne:update()
    Throne.super.update(self)

    local scene = scenemanager.get()
    local player = scene.player
    if self.king.dead
    and utils.distance(self.x,self.y,player.x,player.y) <= 200 then
        scene.cutscene = WinCutscene(self)
    end
end
