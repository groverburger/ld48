Player = class()

local sprite = utils.newAnimation("assets/sprites/lad.png")
local gunarm = lg.newImage("assets/sprites/gunarm.png")

local animations = {
    idle = {1,2},
    walk = {1,3},
}

function Player:new(x,y)
    self.x = x
    self.y = y
    self.speed = {x=0,y=0}
    self.xdir = 1
    self.animIndex = 1
    self.animTimer = 0
end

function Player:update()
    local walkSpeed = 1.5
    if love.keyboard.isDown("d") then
        self.speed.x = self.speed.x + walkSpeed
        self.speed.x = self.speed.x * 0.9
        self.xdir = 1
    elseif love.keyboard.isDown("a") then
        self.speed.x = self.speed.x - walkSpeed
        self.speed.x = self.speed.x * 0.9
        self.xdir = -1
    else
        self.speed.x = self.speed.x * 0.75
    end

    self.speed.y = self.speed.y + 1

    if self.y >= 500 then
        self.y = 500
        self.speed.y = 0

        if love.keyboard.isDown("space") then
            self.speed.y = -15
        end
    end

    -- integrate speed into position
    for i, v in pairs(self.speed) do
        self[i] = self[i] + v
    end

    if math.abs(self.speed.x) > 0.1 then
        self:animate(animations.walk)
    else
        self:animate(animations.idle)
    end
end

function Player:animate(anim)
    self.animTimer = self.animTimer + (anim.speed or 0.1)
    self.animTimer = ((self.animTimer-1) % #anim) + 1
    self.animIndex = anim[math.floor(self.animTimer)]
end

function Player:draw()
    local interp = engine.getInterpolation()
    local dx, dy = self.x + self.speed.x * interp, self.y + self.speed.y * interp

    lg.setColor(1,1,1)
    local gunAngle = utils.angle(self.x, self.y, love.mouse.getPosition())
    local gunflip = utils.sign(math.cos(gunAngle))
    lg.draw(sprite.source, sprite[self.animIndex], dx, dy, 0, gunflip, 1, 24, 32)
    lg.draw(gunarm, dx + 7*gunflip, dy + 10, gunAngle, 1, gunflip, 0, 16)
end
