Warp = class(Thing)

local warpSprite = utils.newAnimation("assets/sprites/warp.png")

function Warp:new(x, y)
    Warp.super.new(self, x, y+56)
    self.sprite = warpSprite
end

function Warp:update()
    local scene = scenemanager.get()
    local player = scene.player
    if math.abs(player.x - self.x) <= 80 and self.y - player.y < 128 then
        player.currentWarp = self
    elseif player.currentWarp == self then
        player.currentWarp = nil
    end
end
