--[[
	FIRST CHAIR — server entry point.
	Builds the world, starts saving + case services, and loads players' progress.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared").Net)
Net.init()

local World = require(script.World)
local Cast = require(script.World.Cast)
local DataService = require(script.DataService)
local CaseService = require(script.CaseService)
local LobbyService = require(script.LobbyService)

World.build()
Cast.build()
DataService.start()
CaseService.start()
LobbyService.start()

local function onPlayerAdded(player: Player)
	DataService.load(player)
	LobbyService.setupPlayer(player, CaseService.summary(player))
	if not DataService.isSaving(player) then
		local notice = Net.event("Notice")
		notice:FireClient(player, {
			kind = "warning",
			text = "Progress can't be saved right now — you can still play.",
		})
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
