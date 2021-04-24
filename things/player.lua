Player = class()

local sprite = utils.newAnimation("assets/sprites/lad.png")
local gunarm = lg.newImage("assets/sprites/gunarm.png")
local wasSpaceDown = false

local animations = {
    idle = {1,2},
    walk = {1,3},
}

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
end

function Player:update()
    local walkSpeed = 1.1
    local airSpeed = 0.5
    local walkFriction = 0.9
    local stopFriction = 0.75
    local maxWalkSpeed = 8--walkSpeed / (1-walkFriction)
    local scene = scenemanager.get()
    local width, height = 16, 32

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
        if not wasOnGround then
            self.stretch.x = 1.4
            self.stretch.y = 0.5
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
    if self.coyoteFrames > 0 and love.keyboard.isDown("space") and not wasSpaceDown then
        self.coyoteFrames = 0
        self.speed.y = -15
        self.stretch.x = 0.5
        self.stretch.y = 1.4

        if self.onWall ~= 0 then
            self.speed.x = self.onWall*-0.8*maxWalkSpeed
            self.onWall = 0
            self.disabledAirControl = 7
        end
    end
    self.coyoteFrames = math.max(self.coyoteFrames - 1, 0)
    self.disabledAirControl = math.max(self.disabledAirControl - 1, 0)

    -- variable jump height
    if not love.keyboard.isDown("space") and self.speed.y < 0 then
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
        if love.keyboard.isDown("d") then
            self.speed.x = self.speed.x + speed
            self.speed.x = math.min(self.speed.x, maxWalkSpeed)
            walking = true
        elseif love.keyboard.isDown("a") then
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
    self.onWall = 0
    if not self.onGround then
        if scene:isSolid(self.x+width+2, self.y+height-4) then
            self.onWall = 1
            self.coyoteFrames = 7
        end
        if scene:isSolid(self.x-width-2, self.y+height-4) then
            self.onWall = -1
            self.coyoteFrames = 7
        end
    end

    -- integrate x
    self.x = self.x + self.speed.x

    -- death plane
    if self.y > 20*64 then
        for i, v in pairs(self.spawnPoint) do
            self[i] = v
            self.speed[i] = 0
        end
    end

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
    end

    for i, v in pairs(self.stretch) do
        self.stretch[i] = utils.lerp(v, 1, 0.25)
    end

    wasSpaceDown = love.keyboard.isDown("space")
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
    local sx, sy = lg.transformPoint(dx, dy)
    local gunAngle = utils.angle(sx, sy, love.mouse.getPosition())
    local gunflip = utils.sign(math.cos(gunAngle))
    lg.draw(sprite.source, sprite[self.animIndex], dx, dy + 32*math.max(1-self.stretch.y, 0), 0, gunflip*self.stretch.x, self.stretch.y, 24, 32)
    lg.draw(gunarm, dx + 7*gunflip, dy + 10, gunAngle, 1, gunflip, 0, 16)
end
