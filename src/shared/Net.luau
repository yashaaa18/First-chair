--[[
	Net — names of every remote. The server creates them; the client waits for them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

Net.FOLDER = "FirstChairRemotes"

Net.Functions = {
	"GetProfile", -- () -> profile summary
	"StartCase", -- (caseId) -> sanitized case + seen dialogue
	"Submit", -- (caseId, stepIndex, answer) -> result
	"AbandonCase", -- () -> true
}

Net.Events = {
	"Notice", -- server -> client: { kind, text }
	"Broadcast", -- server -> everyone: { kind, text } (someone won a case)
	"Leaderboard", -- server -> client: { { name, points, userId }, ... }
}

local folder: Folder? = nil

local function getFolder(): Folder
	local cached = folder
	if cached then
		return cached
	end
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(Net.FOLDER) :: Folder?
		if not existing then
			local created = Instance.new("Folder")
			created.Name = Net.FOLDER
			for _, name in Net.Functions do
				local rf = Instance.new("RemoteFunction")
				rf.Name = name
				rf.Parent = created
			end
			for _, name in Net.Events do
				local re = Instance.new("RemoteEvent")
				re.Name = name
				re.Parent = created
			end
			created.Parent = ReplicatedStorage
			existing = created
		end
		folder = existing
		return existing
	end
	local found = ReplicatedStorage:WaitForChild(Net.FOLDER) :: Folder
	folder = found
	return found
end

function Net.fn(name: string): RemoteFunction
	return getFolder():WaitForChild(name) :: RemoteFunction
end

function Net.event(name: string): RemoteEvent
	return getFolder():WaitForChild(name) :: RemoteEvent
end

function Net.init()
	getFolder()
end

return Net
