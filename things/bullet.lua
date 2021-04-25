require "things/thing"

Bullet = class(Thing)
Bullet.sprite = utils.newAnimation("assets/sprites/bullet.png")
local sound = soundsystem.newSound("assets/sounds/gun1.wav"):setBaseVolume(0.7)
local esound = soundsystem.newSound("assets/sounds/ebullet.wav"):setBaseVolume(0.4)
local colSound = soundsystem.newSound("assets/sounds/bulletcol.wav"):setBaseVolume(0.3)

function Bullet:new(x,y,angle,owner,speed,time)
    Bullet.super.new(self, x,y)

    self.speed.mag = speed or 30
    self.speed.x, self.speed.y = utils.lengthdir(angle, self.speed.mag)
    self.life = Alarm():set(time or 18)
    self.animIndex = 0
    self.size = 1
    local player = scenemanager.get().player
    self.owner = owner or player
    self.firstFrame = true

    if self.owner == player then
        sound:play(utils.randomRange(0.8,1.2))
    end
end

function Bullet:update()
    local scene = scenemanager.get()
    self.x = self.x + self.speed.x
    self.y = self.y + self.speed.y

    if self.firstFrame and self:isLevelActive() and self.owner ~= scene.player then
        esound:play(utils.randomRange(0.8,1.2))
        self.firstFrame = false
    end

    for i=1, self.speed.mag, 2 do
        local angle = utils.angle(0,0,self.speed.x,self.speed.y)
        local hit = self:isSolid(self.x + math.cos(angle)*i, self.y + math.sin(angle)*i, true)
        if hit and not self.dead then
            if self:isLevelActive() then colSound:play() end
            self:createThing(Impact(self.x,self.y))
        end
        self.dead = self.dead or hit
    end

    self.life:update()
    self.dead = self.dead or not self.life:isActive()

    if self.animIndex == 0 then
        self.animIndex = 1
    else
        self.animIndex = 2
    end

    if not self.owner:instanceOf(Enemy) then
        for _, enemy in ipairs(scene.enemyList) do
            if enemy:collisionAt(self.x,self.y)
            and enemy.levelIndex == self.levelIndex
            and enemy ~= self.owner then
                enemy:hit(self)
                self.dead = true
                self:createThing(Impact(self.x,self.y))
            end
        end
    end

    local player = scene.player
    if math.abs(self.x - player.x) <= 12
    and math.abs(self.y - player.y) <= 32
    and player ~= self.owner
    and self:isLevelActive() then
        player:hit(self)
        self.dead = true
        self:createThing(Impact(self.x,self.y))
    end
end

function Bullet:draw()
    if self.animIndex == 0 then self.animIndex = 1 end

    local r,g,b,a = lg.getColor()

    self.size = 1
    if self.animIndex == 2 then
        colors.red(a)
        self:subdraw(self.x + self.speed.x*-1, self.y + self.speed.y*-1)
        self:subdraw(self.x + self.speed.x*-0.5,  self.y + self.speed.y*-0.5)
        colors.white(a)
        self:subdraw()
    else
        self.size = 1.5
        self:subdraw()
    end
end
