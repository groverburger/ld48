local soundsystem = {}

local soundList = {}
local musicList = {}
local poolList = {}

-- necessary for the distance stuff to work!
-- because no distances are specified, however, soudns don't fade over distance
-- that part is implemented manually for a custom distance falloff in soundsystem.update
love.audio.setDistanceModel("linear")

--------------------------------------------------------------------------------------------------------------------
-- base sound class
--------------------------------------------------------------------------------------------------------------------

local sound = class()
sound.basePitch = 1
sound.baseVolume = 1
sound.volume = 1

function sound:new(path, staticness)
    self.source = love.audio.newSource(path, staticness or "static")

    if baseVolume then self.baseVolume = baseVolume end
    if basePitch then self.basePitch = basePitch end
end

function sound:setBaseVolume(volume)
    self.baseVolume = volume
    return self
end

function sound:setBasePitch(pitch)
    self.basePitch = pitch
    return self
end

function sound:setLooping()
    self.source:setLooping(true)
    return self
end

function sound:play(pitch, x,y,z)
    -- web safety
    if not self.source then return end

    self.source:setPitch((pitch or 1) * self.basePitch)

    -- more web safety
    -- web crashes when trying to use seek
    self.source:stop()

    if self:isSpatial() then
        assert(x and y, "Spatial sounds must be given a position!")

        -- custom code to make sounds close to listener more in both ears
        local lx,ly,lz = love.audio.getPosition()
        x = utils.map(math.abs(x - lx), 300,700, lx,x)
        y = utils.map(math.abs(y - ly), 300,700, ly,y)

        -- for some math to calculate the volume based on distance later
        self.source:setPosition(x,y,z or 0)
    end

    -- play on the next frame
    -- so that this sound can get updated before it starts playing
    -- preventing weird sound cutoff glitches
    --self.queuedPlay = true
    self.source:setVolume(self.volume * self.baseVolume)
    self.source:play()

    return self
end

function sound:stop()
    self.source:stop()
    return self
end

-- modifiers

function sound:setVolume(volume)
    self.volume = volume
    return self
end

function sound:spatialize(min,max)
    self.spatial = true
    self.minDistanceRange = min or 0
    self.maxDistanceRange = max or 1500
    return self
end

function sound:isSpatial()
    return self.spatial
end

--------------------------------------------------------------------------------------------------------------------
-- pooled sound class
--------------------------------------------------------------------------------------------------------------------

local pooledSound = class()
pooledSound.index = 1

function pooledSound:new(...)
    self.ownerOfIndex = {}
    poolList[self] = self
    for i=1, 5 do
        self[i] = soundsystem.newSound(...)
    end
end

-- just play a one off sound from this pool
function pooledSound:play(...)
    self[self.index]:play(...)
    self.index = self.index + 1
    if self.index > #self then
        self.index = 1
    end
    return self[self.index]
end

-- stops all sounds in this pool
function pooledSound:stop()
    self.ownerOfIndex = {}
    for _, sound in ipairs(self) do
        sound:stop()
    end
    return self
end

-- sound ownership is useful for long sounds, and sounds that loop
-- so that an object can stop the sound that it started
function pooledSound:ownAndPlay(owner, ...)
    -- if owner already owns something, just return
    for i, sound in ipairs(self) do
        if self.ownerOfIndex[i] == owner then
            return
        end
    end

    if not self.ownerOfIndex[self.index] then
        self.ownerOfIndex[self.index] = owner
        return self:play(...)
    end
end

function pooledSound:disownAndStop(owner)
    local soundToStop, soundIndex

    -- look through my sounds and figure out which one this owner owns
    for i, sound in ipairs(self) do
        if self.ownerOfIndex[i] == owner then
            soundToStop = sound
            soundIndex = i
            break
        end
    end

    -- no sound was found, just return
    if not soundToStop then return end

    -- a sound was found, stop it and return it
    self.ownerOfIndex[soundIndex] = nil
    soundToStop:stop()
    return soundToStop
end

-- stop and release all sounds from their owners that are no longer playing
function pooledSound:cull()
    for i, sound in ipairs(self) do
        if not sound.source:isPlaying() and self.ownerOfIndex[i] then
            self.ownerOfIndex[i] = nil
            sound:stop()
        end
    end
end

-- modifiers

function pooledSound:setBaseVolume(...)
    for _, sound in ipairs(self) do
        sound:setBaseVolume(...)
    end
    return self
end

function pooledSound:setBasePitch(...)
    for _, sound in ipairs(self) do
        sound:setBasePitch(...)
    end
    return self
end

function pooledSound:setVolume(...)
    for _, sound in ipairs(self) do
        sound:setVolume(...)
    end
    return self
end

function pooledSound:spatialize(...)
    for _, sound in ipairs(self) do
        sound:spatialize(...)
    end
    return self
end

function pooledSound:isSpatial()
    for _, sound in ipairs(self) do
        if sound:isSpatial() then
            return true
        end
    end

    return false
end

function pooledSound:setLooping()
    for _, sound in ipairs(self) do
        sound:setLooping()
    end
    return self
end

--------------------------------------------------------------------------------------------------------------------
-- sound api
--------------------------------------------------------------------------------------------------------------------

function soundsystem.newSound(...)
    local this = sound(...)
    soundList[this] = this
    return this
end

function soundsystem.newPooledSound(...)
    return pooledSound(...)
end

function soundsystem.newMusic(path, volume)
    local this = sound(path, "stream")
    this:setBaseVolume(volume or 1)
    musicList[this] = this
    this.source:setLooping(true)
    return this
end

--------------------------------------------------------------------------------------------------------------------
-- updating and controlling sounds
--------------------------------------------------------------------------------------------------------------------

function soundsystem.update(soundVolume, musicVolume)
    for _,sound in pairs(musicList) do
        sound.source:setVolume(sound.volume * sound.baseVolume * musicVolume^2)

        if sound.queuedPlay then
            sound.queuedPlay = false
            sound.source:play()
        end
    end

    for _,sound in pairs(soundList) do
        local source = sound.source
        local multipliedVolume = sound.volume * sound.baseVolume * soundVolume^2

        -- hack for custom distance attentuation based for a squared falloff on a custom range
        if sound:isSpatial() then
            local lx,ly,lz = love.audio.getPosition()
            local x,y,z = sound.source:getPosition()
            local dist = math.sqrt((lx - x)^2 + (ly - y)^2 + (lz - z)^2)
            local min = sound.minDistanceRange
            local max = sound.maxDistanceRange
            local distVolume = utils.map(dist, min, max, 1, 0)^2
            multipliedVolume = multipliedVolume * distVolume
        end

        source:setVolume(multipliedVolume)

        if sound.queuedPlay then
            sound.queuedPlay = false
            sound.source:play()
        end
    end

    -- cull sounds that aren't being played
    for _,pool in pairs(poolList) do
        pool:cull()
    end
end

local pausedSounds
local hasPaused = false
function soundsystem.pause()
    if not hasPaused then
        pausedSounds = love.audio.pause()
        hasPaused = true
    end
end

function soundsystem.resume()
    if hasPaused then
        hasPaused = false
        love.audio.play(pausedSounds)
    end
end

function soundsystem.getPausedSoundsList()
    return hasPaused and pausedSounds
end

function soundsystem.stop()
    for name, sound in pairs(soundList) do
        sound:stop()
    end
end

function soundsystem.stopAllSounds()
    for name, sound in pairs(soundList) do
        if musicList[sound] then
            sound:stop()
        end
    end
end

function soundsystem.stopAllMusic()
    for _,sound in pairs(musicList) do
        sound:stop()
    end
end

function soundsystem.getDistanceFromListener(x,y,z)
    local lx,ly,lz = love.audio.getPosition()
    return math.sqrt((x-lx)^2 + (y-ly)^2 + (z and ((z-lz)^2) or 0))
end

return soundsystem
