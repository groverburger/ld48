local audio = {}
audio.soundVolume = 1
audio.musicVolume = 1
audio.masterVolume = 1

local soundList = {}
local musicList = {}

local noise = class()
noise.pitch = {0.8, 1.2}
noise.volume = 1

local function updateNoiseVolume(noise)
    noise.source:setVolume(noise.volume * (noise.isSound and audio.soundVolume or audio.musicVolume))
end

function noise:new(path, isSound)
    self.source = love.audio.newSource(path, isSound and "static" or "stream")
    self.isSound = isSound
end

function noise:play()
    -- pitch can either be a range or a set value
    if type(self.pitch) == "table" then
        self.source:setPitch(utils.randomRange(self.pitch[1], self.pitch[2]))
    else
        self.source:setPitch(self.pitch)
    end

    updateNoiseVolume(self)

    -- reset the noise from the beginning in a web-safe way (seek(0) doesn't work)
    self.source:stop()
    self.source:play()
end

--------------------------------------------------------------------------------
-- public api
--------------------------------------------------------------------------------

function audio.newSound(path, volume, pitch)
    local sound = noise(path, true)
    if volume then sound.volume = volume end
    if pitch then sound.pitch = pitch end
    table.insert(soundList, sound)
    return sound
end

function audio.newMusic(music, volume, pitch)
    local music = noise(path, false)
    if volume then music.volume = volume end
    music.pitch = pitch or 1
    music.source:setLooping(true)
    table.insert(musicList, music)
    return music
end

function audio.setSoundVolume(volume)
    audio.soundVolume = volume
    for _, v in ipairs(soundList) do updateNoiseVolume(v) end
end

function audio.setMusicVolume(volume)
    audio.musicVolume = volume
    for _, v in ipairs(musicList) do updateNoiseVolume(v) end
end

return audio
