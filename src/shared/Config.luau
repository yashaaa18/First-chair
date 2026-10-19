--[[
	Config — the knobs you may want to turn without touching game code.
	Edit this file on github.com, then run "Publish to Roblox".
]]

local Config = {}

--[[
	MUSIC
	1. Upload the tracks in marketing/music/*.ogg: Creator Hub -> Development Items -> Audio -> Upload.
	2. Open each one, copy its Asset ID, and paste it here as "rbxassetid://THE_ID".
	Leave a slot as "" to keep it silent. (Audio you upload yourself is always permitted in your own experience.)
]]
Config.Music = {
	menu = "", -- "Valence": the title screen and the office lobby
	office = "", -- "Case File": investigation scenes
	court = "", -- "Northbridge": the courtroom
	results = "", -- "Verdict": short stinger on the results screen (not looped)
}
Config.MusicVolume = 0.32

--[[
	BADGES
	Create them in Creator Hub -> your experience -> Badges (one-time, 100 Robux each or free with
	the monthly allowance), then paste each badge's ID. 0 means "not set up yet" and is skipped.
]]
Config.Badges = {
	firstVerdict = 0, -- win Case 1
	cleanSweep = 0, -- earn an S on any case
	firstChair = 0, -- win all three cases
}

-- Social lobby
Config.Lobby = {
	visiblePlayers = 16, -- how many other players are drawn around you (nearest first); keeps iPads smooth in big servers
	walkSpeed = 14,
}

-- Engagement
Config.DailyBonusPoints = 10 -- promotion points for the first case won each day
Config.LeaderboardSize = 10
Config.LeaderboardRefreshSeconds = 90
Config.BroadcastVerdicts = true -- "Ressa just won The Signed Lie — Grade S" to everyone in the server

return Config
