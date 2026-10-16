--[[
	Audio — short UI sounds. Uses sounds that ship inside the Roblox client
	(rbxasset://sounds/...), so nothing needs uploading. To use richer sounds,
	replace any SoundId below with an asset from the Creator Store, e.g.
	"rbxassetid://1234567890". Missing sounds fail silently.
]]

local SoundService = game:GetService("SoundService")

local Audio = {}

local DEFS = {
	click = { id = "rbxasset://sounds/clickfast.wav", volume = 0.35, speed = 1.1 },
	page = { id = "rbxasset://sounds/clickfast.wav", volume = 0.25, speed = 0.8 },
	confirm = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.35, speed = 1.0 },
	gain = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.3, speed = 1.25 },
	wrong = { id = "rbxasset://sounds/button.wav", volume = 0.5, speed = 0.55 },
	objection = { id = "rbxasset://sounds/swoosh.wav", volume = 0.7, speed = 0.8 },
	gavel = { id = "rbxasset://sounds/button.wav", volume = 0.9, speed = 0.35 },
	unlock = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.45, speed = 0.75 },
	whoosh = { id = "rbxasset://sounds/swoosh.wav", volume = 0.3, speed = 1.2 },
}

-- Optional background music: paste a Creator Store audio ID here (e.g. "rbxassetid://...").
Audio.MUSIC_ID = ""

local sounds: { [string]: Sound } = {}
local music: Sound? = nil

function Audio.init()
	local folder = Instance.new("Folder")
	folder.Name = "FirstChairSounds"
	for name, def in DEFS do
		local s = Instance.new("Sound")
		s.Name = name
		s.SoundId = def.id
		s.Volume = def.volume
		s.PlaybackSpeed = def.speed
		s.Parent = folder
		sounds[name] = s
	end
	folder.Parent = SoundService

	if Audio.MUSIC_ID ~= "" then
		local m = Instance.new("Sound")
		m.Name = "Music"
		m.SoundId = Audio.MUSIC_ID
		m.Looped = true
		m.Volume = 0.18
		m.Parent = folder
		music = m
		m:Play()
	end
end

function Audio.play(name: string)
	local s = sounds[name]
	if s then
		pcall(function()
			SoundService:PlayLocalSound(s)
		end)
	end
end

function Audio.setMusicVolume(volume: number)
	if music then
		music.Volume = volume
	end
end

return Audio
