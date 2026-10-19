--[[
	Music — one looping track per place in the story, cross-faded as scenes change.
	Track asset IDs come from shared/Config.luau; an empty slot just stays silent.
]]

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Config)

local Music = {}

local sounds: { [string]: Sound } = {}
local current: string? = nil
local enabled = true

local function fade(sound: Sound, volume: number, seconds: number, thenStop: boolean?)
	local tween =
		TweenService:Create(sound, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { Volume = volume })
	tween:Play()
	if thenStop then
		tween.Completed:Connect(function()
			if sound.Volume <= 0.001 then
				sound:Stop()
			end
		end)
	end
end

function Music.init()
	local f = Instance.new("Folder")
	f.Name = "FirstChairMusic"
	for key, id in Config.Music do
		if type(id) == "string" and id ~= "" then
			local s = Instance.new("Sound")
			s.Name = key
			s.SoundId = id
			s.Looped = key ~= "results"
			s.Volume = 0
			s.Parent = f
			sounds[key] = s
		end
	end
	f.Parent = SoundService
end

function Music.has(key: string): boolean
	return sounds[key] ~= nil
end

-- Cross-fade to a track. Unknown or silent keys fade the current track out.
function Music.play(key: string)
	if current == key then
		return
	end
	local previous = current and sounds[current]
	current = key
	if previous then
		fade(previous, 0, 0.9, true)
	end
	local next = sounds[key]
	if next then
		if not next.IsPlaying then
			next.TimePosition = 0
			next:Play()
		end
		fade(next, if enabled then Config.MusicVolume else 0, 1.4)
	end
end

function Music.stop()
	local playing = current and sounds[current]
	current = nil
	if playing then
		fade(playing, 0, 0.6, true)
	end
end

function Music.setEnabled(on: boolean)
	enabled = on
	local playing = current and sounds[current]
	if playing then
		fade(playing, if on then Config.MusicVolume else 0, 0.4)
	end
end

function Music.isEnabled(): boolean
	return enabled
end

function Music.toggle(): boolean
	Music.setEnabled(not enabled)
	return enabled
end

return Music
