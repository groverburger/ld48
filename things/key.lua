Key = class(Thing)
Key.sprite = utils.newAnimation("assets/sprites/key.png")
Key.keycolor = "#ffffff"

local sound = audio.newSound("assets/sounds/keyget.wav", 0.5)

function Key:new(x,y)
    Key.super.new(self, x,y)
    self.time = 0
end

function Key:update()
    Key.super.update(self)
    self.y = self.y + math.sin(self.time)
    self.time = self.time + 0.1

    local scene = scene()
    local player = scene.player
    if self:isLevelActive()
    and utils.distance(self.x,self.y, player.x,player.y) <= 64
    and self.keycolor then
        self.dead = true
        player.keys[self.keycolor] = true
        sound:play()
    end
end

function Key:draw()
    local r,g,b,a = lg.getColor()
    colors[self.keycolor](a)
    self:subdraw()
end
