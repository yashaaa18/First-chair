--[[
	DataService — loads and saves player progress with DataStoreService.

	Fails gracefully: if Roblox's DataStores are unavailable (e.g. Studio without
	API access, or an outage) the player can still play; progress simply isn't
	saved, and we never overwrite good saved data with a blank profile.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = {}

local STORE_NAME = "FirstChair_Progress_v1"
local MAX_RETRIES = 3
local AUTOSAVE_SECONDS = 120
local MAX_SEEN_KEYS = 400

export type Best = { score: number, maxScore: number, grade: string, percent: number }
export type Data = {
	version: number,
	best: { [string]: Best },
	seen: { [string]: boolean },
	plays: number,
}

type Profile = {
	data: Data,
	loaded: boolean,
	canSave: boolean,
	dirty: boolean,
}

local profiles: { [Player]: Profile } = {}
local store: DataStore? = nil
local storeError: string? = nil

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		storeError = tostring(result)
		warn("[FirstChair] DataStore unavailable — progress will not save this session:", storeError)
	end
end

local function defaultData(): Data
	return { version = 1, best = {}, seen = {}, plays = 0 }
end

-- Never trust stored data blindly: rebuild a clean table from known fields.
local function sanitize(raw: any): Data
	local data = defaultData()
	if type(raw) ~= "table" then
		return data
	end
	if type(raw.best) == "table" then
		for caseId, best in raw.best do
			if
				type(caseId) == "string"
				and type(best) == "table"
				and type(best.score) == "number"
				and type(best.grade) == "string"
			then
				data.best[caseId] = {
					score = best.score,
					maxScore = if type(best.maxScore) == "number" then best.maxScore else best.score,
					grade = best.grade,
					percent = if type(best.percent) == "number" then best.percent else 0,
				}
			end
		end
	end
	if type(raw.seen) == "table" then
		local count = 0
		for key, value in raw.seen do
			if type(key) == "string" and value == true and count < MAX_SEEN_KEYS then
				data.seen[key] = true
				count += 1
			end
		end
	end
	if type(raw.plays) == "number" then
		data.plays = raw.plays
	end
	return data
end

local function withRetries<T>(label: string, fn: () -> T): (boolean, T | string)
	local lastErr: any = nil
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		local message = tostring(result)
		if string.find(message, "StudioAccessToApisNotAllowed") or string.find(message, "403") then
			-- Studio without API access: retrying won't help.
			break
		end
		warn(
			("[FirstChair] %s failed (attempt %d/%d): %s"):format(
				label,
				attempt,
				MAX_RETRIES,
				tostring(result)
			)
		)
		task.wait(attempt * 1.5)
	end
	return false, tostring(lastErr)
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

function DataService.load(player: Player): Profile
	local profile: Profile = { data = defaultData(), loaded = false, canSave = false, dirty = false }
	profiles[player] = profile

	if not store then
		profile.loaded = true
		return profile
	end

	local ok, result = withRetries("Load " .. player.Name, function()
		return (store :: DataStore):GetAsync(keyFor(player))
	end)

	if ok then
		profile.data = sanitize(result)
		profile.canSave = true
	else
		-- Load failed: play on with a blank profile but DON'T save over real data.
		profile.canSave = false
	end
	profile.loaded = true
	return profile
end

function DataService.get(player: Player): Profile?
	return profiles[player]
end

function DataService.waitFor(player: Player, timeout: number?): Profile?
	local deadline = os.clock() + (timeout or 15)
	while os.clock() < deadline do
		local profile = profiles[player]
		if profile and profile.loaded then
			return profile
		end
		if not player.Parent then
			return nil
		end
		task.wait(0.1)
	end
	return profiles[player]
end

function DataService.isSaving(player: Player): boolean
	local profile = profiles[player]
	return profile ~= nil and profile.canSave
end

function DataService.markDirty(player: Player)
	local profile = profiles[player]
	if profile then
		profile.dirty = true
	end
end

function DataService.save(player: Player): boolean
	local profile = profiles[player]
	if not profile or not profile.canSave or not store then
		return false
	end
	local snapshot = table.clone(profile.data)
	local ok = withRetries("Save " .. player.Name, function()
		return (store :: DataStore):UpdateAsync(keyFor(player), function(old)
			-- Merge: keep the better grade per case so a stale server can't regress progress.
			local merged = sanitize(snapshot)
			local previous = sanitize(old)
			for caseId, best in previous.best do
				local mine = merged.best[caseId]
				if not mine or best.score > mine.score then
					merged.best[caseId] = best
				end
			end
			for key in previous.seen do
				merged.seen[key] = true
			end
			merged.plays = math.max(merged.plays, previous.plays)
			return merged
		end)
	end)
	if ok then
		profile.dirty = false
	end
	return ok
end

function DataService.release(player: Player)
	local profile = profiles[player]
	if profile and profile.dirty then
		DataService.save(player)
	end
	profiles[player] = nil
end

function DataService.start()
	Players.PlayerRemoving:Connect(function(player)
		DataService.release(player)
	end)

	game:BindToClose(function()
		if RunService:IsStudio() and not store then
			return
		end
		local pending = 0
		for player, profile in profiles do
			if profile.dirty then
				pending += 1
				task.spawn(function()
					DataService.save(player)
					pending -= 1
				end)
			end
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.2)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player, profile in profiles do
				if profile.dirty and profile.canSave then
					task.spawn(DataService.save, player)
				end
			end
		end
	end)
end

DataService.storeAvailable = function(): boolean
	return store ~= nil
end

return DataService
