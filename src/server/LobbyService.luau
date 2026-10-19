--[[
	LobbyService — everything social: leaderstats and career titles over heads, the
	Top Associates leaderboard (OrderedDataStore + the board in the lobby), badges,
	and the server-wide "X just won a case" announcements.
	Every external call is wrapped so an outage never breaks the game.
]]

local BadgeService = game:GetService("BadgeService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local CaseCatalog = require(Shared.CaseCatalog)

local LobbyService = {}

local LEADERBOARD_STORE = "FirstChair_Points_v1"

local orderedStore: OrderedDataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetOrderedDataStore(LEADERBOARD_STORE)
	end)
	if ok then
		orderedStore = result
	else
		warn("[FirstChair] Leaderboard store unavailable:", result)
	end
end

local nameCache: { [number]: string } = {}
local board: { { name: string, points: number, userId: number } } = {}

----------------------------------------------------------------- leaderstats + attributes
function LobbyService.setupPlayer(player: Player, summary)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		local title = Instance.new("StringValue")
		title.Name = "Title"
		title.Parent = stats
		local points = Instance.new("IntValue")
		points.Name = "Points"
		points.Parent = stats
		stats.Parent = player
	end
	LobbyService.refreshPlayer(player, summary)
	nameCache[player.UserId] = player.DisplayName
end

function LobbyService.refreshPlayer(player: Player, summary)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		(stats:FindFirstChild("Title") :: StringValue).Value = summary.title;
		(stats:FindFirstChild("Points") :: IntValue).Value = summary.points
	end
	-- Attributes replicate to every client: nametags read these.
	player:SetAttribute("Title", summary.title)
	player:SetAttribute("Points", summary.points)
	player:SetAttribute("Streak", summary.streak or 0)
end

----------------------------------------------------------------- leaderboard
local function nameFor(userId: number): string
	local cached = nameCache[userId]
	if cached then
		return cached
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local resolved = if ok then name else "Associate"
	nameCache[userId] = resolved
	return resolved
end

local function renderBoard()
	local world = workspace:FindFirstChild("FirstChairWorld")
	local part = world and world:FindFirstChild("LeaderboardBoard", true)
	local gui = part and part:FindFirstChildOfClass("SurfaceGui")
	local list = gui and gui:FindFirstChild("List") :: TextLabel?
	if not list then
		return
	end
	if #board == 0 then
		list.Text = "Win a case to make the board."
		return
	end
	local lines = {}
	for i, entry in board do
		table.insert(lines, ("%d.  %s   —   %d pts"):format(i, entry.name, entry.points))
	end
	list.Text = table.concat(lines, "\n")
end

function LobbyService.refreshBoard()
	if not orderedStore then
		return
	end
	local ok, pages = pcall(function()
		return (orderedStore :: OrderedDataStore):GetSortedAsync(false, Config.LeaderboardSize)
	end)
	if not ok then
		warn("[FirstChair] Leaderboard read failed:", pages)
		return
	end
	local fresh = {}
	for _, item in pages:GetCurrentPage() do
		local userId = tonumber(string.match(item.key, "%d+"))
		if userId then
			table.insert(fresh, { userId = userId, name = nameFor(userId), points = item.value })
		end
	end
	board = fresh
	renderBoard()
	Net.event("Leaderboard"):FireAllClients(board)
end

function LobbyService.recordPoints(player: Player, points: number)
	if not orderedStore or points <= 0 then
		return
	end
	task.spawn(function()
		local ok, err = pcall(function()
			(orderedStore :: OrderedDataStore):SetAsync("player_" .. player.UserId, points)
		end)
		if not ok then
			warn("[FirstChair] Leaderboard write failed:", err)
		end
	end)
end

----------------------------------------------------------------- badges + announcements
function LobbyService.awardBadge(player: Player, key: string)
	local id = Config.Badges[key]
	if not id or id == 0 then
		return
	end
	task.spawn(function()
		pcall(function()
			if not BadgeService:UserHasBadgeAsync(player.UserId, id) then
				BadgeService:AwardBadge(player.UserId, id)
			end
		end)
	end)
end

function LobbyService.broadcast(text: string, kind: string?)
	Net.event("Broadcast"):FireAllClients({ text = text, kind = kind or "info" })
end

-- Called by CaseService when a case is completed.
function LobbyService.onCaseWon(player: Player, caseId: string, outcome, summary)
	LobbyService.refreshPlayer(player, summary)
	LobbyService.recordPoints(player, summary.points)

	if caseId == "case1" then
		LobbyService.awardBadge(player, "firstVerdict")
	end
	if outcome.grade == "S" then
		LobbyService.awardBadge(player, "cleanSweep")
	end
	local all = true
	for _, id in CaseCatalog.order do
		if not summary.cases[id].best then
			all = false
		end
	end
	if all then
		LobbyService.awardBadge(player, "firstChair")
	end

	if Config.BroadcastVerdicts then
		local info = CaseCatalog.get(caseId)
		LobbyService.broadcast(
			("%s just won %s  ·  Grade %s"):format(
				player.DisplayName,
				info and info.title or caseId,
				outcome.grade
			),
			"success"
		)
	end
end

function LobbyService.start()
	Net.event("Leaderboard") -- ensure it exists
	Players.PlayerAdded:Connect(function(player)
		task.delay(2, function()
			if player.Parent and #board > 0 then
				Net.event("Leaderboard"):FireClient(player, board)
			end
		end)
	end)
	task.spawn(function()
		while true do
			LobbyService.refreshBoard()
			task.wait(Config.LeaderboardRefreshSeconds)
		end
	end)
end

return LobbyService
