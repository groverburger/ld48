Warp = class(Thing)

local warpSprite = utils.newAnimation("assets/sprites/warp.png")

local stepSound = soundsystem.newSound("assets/sounds/steponwarp.wav"):setBaseVolume(0.25)

local ready = {2}
local notready = {1}

function Warp:new(x, y)
    Warp.super.new(self, x, y)
    self.sprite = warpSprite
    self.oy = y+56
end

function Warp:update()
    local scene = scenemanager.get()
    local player = scene.player
    if math.abs(player.x - self.x) <= 80 and self.y - player.y < 128 and player.y < self.y then
        if player.currentWarp ~= self then
            stepSound:play()
        end

        player.currentWarp = self
    elseif player.currentWarp == self then
        player.currentWarp = nil
    end

    if player.currentWarp == self then
        self:animate(ready)
        self.y = self.oy - 8
    else
        self:animate(notready)
        self.y = self.oy
    end
end
