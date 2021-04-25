require "things/enemies/enemy"

King = class(Enemy)
King.sprite = utils.newAnimation("assets/sprites/king.png")
King.state = 1

local throne = lg.newImage("assets/sprites/throne.png")

local startSound = soundsystem.newSound("assets/sounds/bossstart.wav")
local laughSound = soundsystem.newSound("assets/sounds/bosslaugh.wav")
local teleportSound = soundsystem.newSound("assets/sounds/bosstp.wav")
local impactSound = soundsystem.newSound("assets/sounds/bossimpact.wav")

local function randomize(self)
    local choices = {
        self.shoot,
        self.radialShoot,
        self.teleport,
        self.summon,
    }

    local scene = scenemanager.get()
    if #scene.enemyList > 15 then
        lume.remove(choices, self.summon)
    end

    self.alarms.action.callback = utils.choose(choices)
    self.alarms.action:set(60)
end

function King:shoot()
    randomize(self)
    self.bulletStream = 35
end

function King:radialShoot()
    randomize(self)

    for i=0, math.pi*2, math.pi*2/16 do
        self:createThing(Bullet(self.x,self.y,i,self,8,100))
    end
end

function King:teleport()
    randomize(self)

    teleportSound:play(utils.randomRange(0.8,1.2))

    local angle = math.random()*2*math.pi
    local r = utils.randomRange(0,500)
    self.x = self.ox + math.cos(angle)*r
    self.y = self.oy + math.abs(math.sin(angle))*r*-1
end

local summonball = class(Thing)

function summonball:new(x,y,type)
    summonball.super.new(self,x,y)
    self.type = type
    self.angle = math.random()*2*math.pi
    self.speed = math.random() < 0.5 and 5 or 3
    self.alarms = {
        main = Alarm(self.summon, self):set(utils.randomRange(40,60)),
    }
end

function summonball:update()
    summonball.super.update(self)
    local spd = self.speed
    local c, s = math.cos(self.angle)*spd, math.sin(self.angle)*spd
    if not self:isSolid(self.x + c, self.y, true,true,true) then
        self.x = self.x + c
    end
    if not self:isSolid(self.x, self.y + s, true,true,true) then
        self.y = self.y + s
    end
end

function summonball:summon()
    local x, y = self.x, self.y
    if self.type == StillStar then
        x = x - 32
        y = y - 32
    end
    self:createThing(self.type(x,y))
    self.dead = true
end

function summonball:draw()
    local r,g,b,a = lg.getColor()
    colors.blue(a)
    lg.circle("fill",self.x,self.y,24)
end

function King:summon()
    randomize(self)

    local type = utils.choose({
        Star,
        StillStar,
    })

    local amount = math.random() < 0.5 and 3 or 2

    for i=1, amount do
        self:createThing(summonball(self.x,self.y,type))
    end
end

local function wakeup(self)
    self.state = 2
    scenemanager.get().cameraTracking = true
    randomize(self)
    impactSound:play()
end

local function laugh(self)
    laughSound:play(utils.randomRange(0.8,1.2))
    self.alarms.laugh:set(utils.randomRange(60*6,60*10)*2)
end

function King:new(x,y)
    King.super.new(self, x+128,y+128)
    self.hp = 70
    self.ohp = self.hp
    self.ox = x+128
    self.oy = y+128
    self.bulletStream = 0

    self.alarms = {
        wakeup = Alarm(wakeup, self),
        action = Alarm(randomize, self),
        laugh = Alarm(laugh, self):set(200),
    }
end

function King:update()
    King.super.update(self)
    local scene = scenemanager.get()
    local player = scene.player

    if self.state == 1 and self:isLevelActive() and not self.alarms.wakeup:isActive() then
        self.alarms.wakeup:set(130)
        scene.cameraTracking = false
        startSound:play()
    end

    if self.alarms.wakeup:isActive() then
        scene.camera.x = utils.lerp(scene.camera.x, self.x, 0.1)
        scene.camera.y = utils.lerp(scene.camera.y, self.y, 0.1)
    end

    if self.bulletStream > 0 then
        self.bulletStream = self.bulletStream - 1

        if self.bulletStream%7 == 0 then
            local angle = utils.angle(self.x,self.y, player.x,player.y)
            local off = 0.075
            self:createThing(Bullet(self.x,self.y,angle,self,8,100))
            self:createThing(Bullet(self.x,self.y,angle+off,self,8,100))
            self:createThing(Bullet(self.x,self.y,angle-off,self,8,100))
        end
    end

    self.animIndex = self.state
end

function King:onDeath()
    local scene = scenemanager.get()
    scene.win = true

    scene.enemyList = {}
    local i = 1
    while i <= #scene.thingList do
        local thing = scene.thingList[i]

        if thing:instanceOf(Enemy)
        or thing:instanceOf(Bullet)
        or thing:instanceOf(summonball) then
            thing.dead = true
            if thing.onDeath then
                thing:onDeath()
            end
            table.remove(scene.thingList, i)
        else
            i = i + 1
        end
    end
end

function King:hit(attacker)
    if self.state == 2 then
        King.super.hit(self, attacker)
    end
end

function King:draw()
    lg.draw(throne, 640, 15*64/2 - 36, 0, 1, 1, throne:getWidth()/2, throne:getHeight()/2)

    local wakeshake = self.alarms.wakeup:isActive() and self.alarms.wakeup:getProgress()*math.cos(math.random()*2*math.pi)*4 or 0
    local dx = self.x + wakeshake
    local dy = self.y
    self:subdraw(dx,dy)

    if self.state == 2 then
        local w = 200
        local h = 10
        lg.setColor(0.1,0.1,0.1)
        lg.rectangle("fill", self.x-w/2,self.y-100,w,h)
        colors.red()
        lg.rectangle("fill", self.x-w/2,self.y-100,w*self.hp/self.ohp,h)
    end
end
