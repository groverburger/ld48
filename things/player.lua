require "things/thing"

Player = class(Thing)

local sprite = utils.newAnimation("assets/sprites/lad.png")
local gunarm = lg.newImage("assets/sprites/gunarm.png")

local jumpSound = soundsystem.newSound("assets/sounds/jump.wav"):setBaseVolume(0.5)
local landSound = soundsystem.newSound("assets/sounds/land.wav"):setBaseVolume(0.25)
local deathSound = soundsystem.newSound("assets/sounds/death.wav"):setBaseVolume()

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

    local scene = scenemanager.get()
    scene:resetLevel()
end

function Player:new(x,y)
    self.x = x
    self.y = y
    self.speed = {x=0,y=0}
    self.spawnPoint = {x=x,y=y}
    self.stretch = {x=1,y=1}

    self.onWall = 0
    self.onGround = false
    self.coyoteFrames = 7
    self.disabledAirControl = 0

    self.animIndex = 1
    self.animTimer = 0

    self.currentWarp = nil
    self.gunAngle = 0
    self.gx, self.gy = x, y
    self.reloaded = true
    self.alarms = {
        gun = Alarm(reload, self):set(8),
        respawn = Alarm(respawn, self),
    }
end

function Player:update()
    local walkSpeed = 1.1
    local airSpeed = 0.7
    local walkFriction = 0.9
    local stopFriction = 0.65
    local maxWalkSpeed = 8--walkSpeed / (1-walkFriction)
    local scene = scenemanager.get()
    local width, height = 12, 32

    -- update all my alarms
    for _, alarm in pairs(self.alarms) do
        alarm:update()
    end

    if self.alarms.respawn:isActive() then return end

    --------------------------------------------------------------------------------
    -- vertical physics
    --------------------------------------------------------------------------------

    -- gravity
    if self.onWall ~= 0 then
        self.speed.y = utils.lerp(self.speed.y, 3, 0.1)
    else
        if self.speed.y <= 0 then
            self.speed.y = self.speed.y + 0.75
        else
            self.speed.y = self.speed.y + 1.5
        end

        self.speed.y = math.min(self.speed.y, 30)
    end

    -- hit ground
    local wasOnGround = self.onGround
    self.onGround = false
    if scene:isSolid(self.x-width,self.y+self.speed.y+height)
    or scene:isSolid(self.x+width,self.y+self.speed.y+height) then
        while not scene:isSolid(self.x-width,self.y+height+1)
        and not scene:isSolid(self.x+width,self.y+height+1) do
            self.y = self.y + 1
        end

        -- squash on first hit
        if not wasOnGround and self.speed.y > 8 then
            self.stretch.x = 1.5
            self.stretch.y = 0.4
            landSound:play(utils.randomRange(0.8,1.2))
        end

        self.speed.y = 0
        self.onGround = true
        self.onWall = 0
        self.coyoteFrames = 7
    end

    -- hit ceiling
    if scene:isSolid(self.x-width,self.y+self.speed.y-height)
    or scene:isSolid(self.x+width,self.y+self.speed.y-height) then
        while not scene:isSolid(self.x-width,self.y-height-1)
        and not scene:isSolid(self.x+width,self.y-height-1) do
            self.y = self.y - 1
        end
        self.speed.y = 1
    end

    -- start the jump
    if self.coyoteFrames > 0 and input.isPressed("jump") then
        if self.currentWarp then
            self.spawnPoint.x = self.x
            self.spawnPoint.y = self.y
            scene.cutscene = WarpCutscene(self.currentWarp:instanceOf(BackWarp) and -1 or 1)
            return
        end

        self.coyoteFrames = 0
        self.speed.y = -15
        self.stretch.x = 0.4
        self.stretch.y = 1.5

        if self.onWall ~= 0 then
            self.speed.x = self.onWall*-0.8*maxWalkSpeed
            self.onWall = 0
            self.disabledAirControl = 7
        end

        jumpSound:play(utils.randomRange(0.8,1.2))
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
    if scene:isSolid(self.x+self.speed.x-width,self.y+height-1)
    or scene:isSolid(self.x+self.speed.x-width,self.y-height+1) then
        while not scene:isSolid(self.x-1-width,self.y+height-1)
        and not scene:isSolid(self.x-1-width,self.y-height+1) do
            self.x = self.x - 1
        end
        self.speed.x = 0
    end

    -- hit right wall
    if scene:isSolid(self.x+self.speed.x+width,self.y+height-1)
    or scene:isSolid(self.x+self.speed.x+width,self.y-height+1) then
        while not scene:isSolid(self.x+1+width,self.y+height-1)
        and not scene:isSolid(self.x+1+width,self.y-height+1) do
            self.x = self.x + 1
        end
        self.speed.x = 0
    end

    -- wall slide collision testing
    if not self.onGround then
        if (scene:isSolidNoOob(self.x+width+2, self.y+height-4)
        or  scene:isSolidNoOob(self.x+width+2, self.y-height+4))
        and scene:isSolidNoOob(self.x+width+2, self.y) then
            self.onWall = 1
            self.coyoteFrames = 7
        end
        if (scene:isSolidNoOob(self.x-width-2, self.y+height-4)
        or  scene:isSolidNoOob(self.x-width-2, self.y-height+4))
        and scene:isSolidNoOob(self.x-width-2, self.y) then
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

    if math.abs(self.speed.x) > 0.1 then
        self:animate(animations.walk)
    else
        self:animate(animations.idle)
    end

    if not self.onGround then
        self.animIndex = 3

        if self.onWall ~= 0 then
            self.animIndex = 4
        end
    end

    for i, v in pairs(self.stretch) do
        self.stretch[i] = utils.lerp(v, 1, 0.25)
    end

    -- shoot!
    if input.isDown("shoot") and self.reloaded then
        self.reloaded = false
        self.alarms.gun:reset()
        local x = self.x + self.gx + math.cos(self.gunAngle)*20
        local y = self.y + self.gy + math.sin(self.gunAngle)*20
        local angle = self.gunAngle + utils.lerp(-0.1,0.1, math.random())
        scene:createThing(Bullet(x,y,angle))
        engine.shake = 5
        self.speed.x = self.speed.x - math.cos(angle)*2
        self.speed.y = self.speed.y - math.sin(angle)*2
    end
end

function Player:die()
    if self.alarms.respawn:isActive() then return end
    deathSound:play()
    self.alarms.respawn:set(60)

    local scene = scenemanager.get()
    for i=1, 3 do
        local x, y = utils.lengthdir(math.random()*2*math.pi, utils.randomRange(10,20))
        x, y = x + self.x, y + self.y
        scene:createThing(Boom(x,y))
    end
end

function Player:hit(attacker)
    self:die()
end

function Player:draw()
    if self.alarms.respawn:isActive() then return end

    local interp = engine.getInterpolation()
    local dx, dy = self.x + self.speed.x * interp, self.y + self.speed.y * interp

    colors.white()
    local sx, sy = lg.transformPoint(dx, dy)
    local gunAngle = utils.angle(sx, sy, input.mouse.x, input.mouse.y)
    local gunflip = utils.sign(math.cos(gunAngle))
    local gx, gy = 7*gunflip, 10
    if self.onWall ~= 0 then
        if gunflip == self.onWall then
            if math.sin(gunAngle) < 0 then
                gunAngle = math.pi*1.5
            else
                gunAngle = math.pi*0.5
            end
        end

        gunflip = -1*self.onWall
        gx = 0
    end

    -- store this calculation for reals here because this is the easiest place to do it
    self.gunAngle = gunAngle
    self.gx, self.gy = gx, gy

    lg.draw(sprite.source, sprite[self.animIndex], dx, dy + 32*math.max(1-self.stretch.y, 0), 0, gunflip*self.stretch.x, self.stretch.y, 24, 32)
    lg.draw(gunarm, dx + gx, dy + gy, gunAngle, 1, gunflip, 0, 16)
end
