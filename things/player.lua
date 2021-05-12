require "things/thing"

Player = class(Thing)

local sprite = utils.newAnimation("assets/sprites/lad.png")
local gunarm = lg.newImage("assets/sprites/gunarm.png")

local jumpSound = audio.newSound("assets/sounds/jump.wav", 0.5)
local landSound = audio.newSound("assets/sounds/land.wav", 0.25)
local deathSound = audio.newSound("assets/sounds/death.wav")

local animations = {
    idle = {1,2},
    walk = {1,3, speed=0.15},
}

local function reload(self)
    self.reloaded = true
end

local function respawn(self)
    for i, v in pairs(self.spawnPoint) do
        self[i] = v
        self.speed[i] = 0
    end
    self.currentWarp = nil
    scene():resetLevel()
end

function Player:new(x,y)
    Player.super.new(self, x,y)
    self.x = x
    self.y = y
    self.speed = {x=0,y=0}
    self.spawnPoint = {x=x,y=y}
    self.stretch = {x=1,y=1}

    self.onWall = 0
    self.onGround = false
    self.coyoteFrames = 7
    self.wannaJumpFrames = 0
    self.disabledAirControl = 0

    self.animIndex = 1
    self.animTimer = 0

    self.keys = {}
    self.currentWarp = nil
    self.gunAngle = 0
    self.newGunAngle = 0
    self.gx, self.gy = x, y
    self.reloaded = true
    self.alarms = {
        gun = Alarm(reload, self):set(8),
        respawn = Alarm(respawn, self),
    }
end

local walkSpeed = 1.1
local airSpeed = 0.7
local walkFriction = 0.9
local stopFriction = 0.65
local maxWalkSpeed = 8--walkSpeed / (1-walkFriction)
local width, height = 12, 32

function Player:update()
    -- update all my alarms
    for _, alarm in pairs(self.alarms) do
        alarm:update()
    end

    if self.alarms.respawn:isActive() then return end

    --------------------------------------------------------------------------------
    -- vertical physics
    --------------------------------------------------------------------------------

    if self.onWall ~= 0 then
        -- slide on wall
        local slideSpeed = 3

        -- change speed more gradually when going up compared to going down
        if self.speed.y < 0 then
            self.speed.y = utils.lerp(self.speed.y, slideSpeed, 0.1)
        else
            self.speed.y = utils.lerp(self.speed.y, slideSpeed, 0.25)
        end
    else
        -- add gravity 
        -- gravity is halved when going up, makes jumps feel better
        if self.speed.y <= 0 then
            self.speed.y = self.speed.y + 0.75
        else
            self.speed.y = self.speed.y + 1.5
        end

        self.speed.y = math.min(self.speed.y, 30)
    end

    -- hit ground
    local wasOnGround = self.onGround
    local iter = 0
    self.onGround = false
    if self:isSolid(self.x-width,self.y+self.speed.y+height, true,true)
    or self:isSolid(self.x+width,self.y+self.speed.y+height, true,true) then
        while not self:isSolid(self.x-width,self.y+height+1, true,true)
        and not self:isSolid(self.x+width,self.y+height+1, true,true)
        and iter < 32 do
            self.y = self.y + 1
            iter = iter + 1
        end

        -- squash on first hit
        if not wasOnGround and self.speed.y > 8 then
            self.stretch.x = 1.5
            self.stretch.y = 0.4
            landSound:play()
        end

        self.speed.y = 0
        self.onGround = true
        self.onWall = 0
        self.coyoteFrames = 7
    end

    -- start the jump
    self.wannaJumpFrames = math.max(self.wannaJumpFrames - 1, 0)
    if input.isPressed("jump") then
        self.wannaJumpFrames = 7
    end

    if self.coyoteFrames > 0 and self.wannaJumpFrames > 0 then
        self:jump()
    end

    -- hit ceiling
    local iter = 0
    if self:isSolid(self.x-width,self.y+self.speed.y-height, true,true)
    or self:isSolid(self.x+width,self.y+self.speed.y-height, true,true) then
        while not self:isSolid(self.x-width,self.y-height-1, true,true)
        and not self:isSolid(self.x+width,self.y-height-1, true,true) 
        and iter < 32 do
            self.y = self.y - 1
            iter = iter + 1
        end
        self.speed.y = 0
    end

    self.coyoteFrames = math.max(self.coyoteFrames - 1, 0)
    if self.coyoteFrames <= 0 then self.onWall = 0 end
    self.disabledAirControl = math.max(self.disabledAirControl - 1, 0)

    -- variable jump height
    if not input.isDown("jump") and self.speed.y < 0 then
        self.speed.y = self.speed.y * 0.7
    end

    -- integrate y
    self.y = self.y + self.speed.y

    --------------------------------------------------------------------------------
    -- horizontal physics
    --------------------------------------------------------------------------------

    -- walk left and right
    local walking = false
    local speed = self.onGround and walkSpeed or airSpeed
    if self.onGround or self.disabledAirControl <= 0 then
        if input.isDown("right") then
            self.speed.x = self.speed.x + speed
            self.speed.x = math.min(self.speed.x, maxWalkSpeed)
            walking = true
        elseif input.isDown("left") then
            self.speed.x = self.speed.x - speed
            self.speed.x = math.max(self.speed.x, -maxWalkSpeed)
            walking = true
        end
    end

    if self.onGround then
        self.speed.x = self.speed.x * (walking and walkFriction or stopFriction)
    end

    -- hit left wall
    local iter = 0
    if self:isSolid(self.x+self.speed.x-width,self.y+height-1, true,true)
    or self:isSolid(self.x+self.speed.x-width,self.y-height+1, true,true) then
        while not self:isSolid(self.x-1-width,self.y+height-1, true,true)
        and not self:isSolid(self.x-1-width,self.y-height+1, true,true)
        and iter < 32 do
            self.x = self.x - 1
            iter = iter + 1
        end
        self.speed.x = 0
    end

    -- hit right wall
    local iter = 0
    if self:isSolid(self.x+self.speed.x+width,self.y+height-1, true,true)
    or self:isSolid(self.x+self.speed.x+width,self.y-height+1, true,true) then
        while not self:isSolid(self.x+1+width,self.y+height-1, true,true)
        and not self:isSolid(self.x+1+width,self.y-height+1, true,true)
        and iter < 32 do
            self.x = self.x + 1
            iter = iter + 1
        end
        self.speed.x = 0
    end

    -- wall slide collision testing
    if not self.onGround then
        if (self:isSolid(self.x+width+2, self.y+height-4, true)
        or  self:isSolid(self.x+width+2, self.y-height+4, true))
        and self:isSolid(self.x+width+2, self.y, true) then
            self.onWall = 1
            self.coyoteFrames = 7
        end
        if (self:isSolid(self.x-width-2, self.y+height-4, true)
        or  self:isSolid(self.x-width-2, self.y-height+4, true))
        and self:isSolid(self.x-width-2, self.y, true) then
            self.onWall = -1
            self.coyoteFrames = 7
        end
    end

    -- integrate x
    self.x = self.x + self.speed.x

    -- death plane
    if self.y >= 15*64 then self:die() end

    --------------------------------------------------------------------------------
    -- animation
    --------------------------------------------------------------------------------

    -- control walking animation
    if math.abs(self.speed.x) > 0.1 then
        self:animate(animations.walk)
    else
        self:animate(animations.idle)
    end

    -- in air and wall sliding animations
    if not self.onGround then
        self.animIndex = 3

        if self.onWall ~= 0 then
            self.animIndex = 4
        end
    end

    -- unsquash and unstretch
    for i, v in pairs(self.stretch) do
        self.stretch[i] = utils.lerp(v, 1, 0.25)
    end

    -- shoot!
    self.gunAngle = self.newGunAngle
    if input.isDown("shoot") and self.reloaded then
        self.reloaded = false
        self.alarms.gun:reset()
        local x = self.x + self.gx + math.cos(self.gunAngle)*20
        local y = self.y + self.gy + math.sin(self.gunAngle)*20
        local angle = self.gunAngle + utils.lerp(-0.1,0.1, math.random())
        self:createThing(Bullet(x,y,angle))
        engine.shake = 5
        self.speed.x = self.speed.x - math.cos(angle)*2
        self.speed.y = self.speed.y - math.sin(angle)*2
    end
end

function Player:jump()
    self.wannaJumpFrames = 0
    self.coyoteFrames = 0

    if self.currentWarp and self.onGround then
        self.spawnPoint.x = self.x
        self.spawnPoint.y = self.y
        scene().cutscene = WarpCutscene(self.currentWarp:instanceOf(BackWarp) and -1 or 1)
        return
    end

    self.speed.y = -15
    self.stretch.x = 0.4
    self.stretch.y = 1.5

    if self.onWall ~= 0 then
        self.speed.x = self.onWall*-0.8*maxWalkSpeed
        self.onWall = 0
        self.disabledAirControl = 7
    end

    jumpSound:play()
end

function Player:die()
    if self.alarms.respawn:isActive() then return end
    deathSound:play()
    self.alarms.respawn:set(60)

    for i=1, 3 do
        local x, y = utils.lengthdir(math.random()*2*math.pi, utils.randomRange(10,20))
        x, y = x + self.x, y + self.y
        self:createThing(Boom(x,y))
    end

    engine.shake = 10
end

-- one hit kills, the hit function is just a reference to the die function
Player.hit = Player.die

function Player:draw()
    if self.alarms.respawn:isActive() then return end

    colors.white()
    local dx, dy = self.x, self.y
    local sx, sy = lg.transformPoint(dx, dy)
    self.newGunAngle = utils.angle(sx, sy, input.mouse.x, input.mouse.y)
    local gunflip = utils.sign(math.cos(self.gunAngle))
    local gx, gy = 7*gunflip, 10
    if self.onWall ~= 0 then
        if gunflip == self.onWall then
            if math.sin(self.gunAngle) < 0 then
                self.gunAngle = math.pi*1.5
            else
                self.gunAngle = math.pi*0.5
            end
        end

        gunflip = -1*self.onWall
        gx = 0
    end

    -- store this calculation for reals here because this is the easiest place to do it
    self.gx, self.gy = gx, gy
    lg.draw(sprite.source, sprite[self.animIndex], dx, dy + 32*math.max(1-self.stretch.y, 0), 0, gunflip*self.stretch.x, self.stretch.y, 24, 32)
    lg.draw(gunarm, dx + gx, dy + gy, self.gunAngle, 1, gunflip, 0, 16)
end
