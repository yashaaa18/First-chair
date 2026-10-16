--[[
	CaseService — the authority on cases.

	* Holds each player's live case session (step, tries, evidence owned).
	* Validates every answer on the server (CaseLogic) — the client is never trusted
	  with answers, scores, unlocks or saved progress.
	* Records best results and derives unlocks/promotion points from them.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Ranks = require(Shared.Ranks)
local CaseCatalog = require(Shared.CaseCatalog)

local CaseLogic = require(script.Parent.CaseLogic)
local DataService = require(script.Parent.DataService)

local CASES = {
	case1 = require(script.Parent.Cases.Case1),
	case2 = require(script.Parent.Cases.Case2),
	case3 = require(script.Parent.Cases.Case3),
}

local CaseService = {}

local sessions: { [Player]: any } = {}
local sanitizedCache: { [string]: any } = {}
local lastCall: { [Player]: { at: number, count: number } } = {}

local RATE_WINDOW = 1
local RATE_MAX = 10

local function rateLimited(player: Player): boolean
	local now = os.clock()
	local entry = lastCall[player]
	if not entry or now - entry.at > RATE_WINDOW then
		lastCall[player] = { at = now, count = 1 }
		return false
	end
	entry.count += 1
	return entry.count > RATE_MAX
end

local function isUnlocked(data, caseId: string): boolean
	local index = CaseCatalog.indexOf(caseId)
	if not index then
		return false
	end
	if index == 1 then
		return true
	end
	local previous = CaseCatalog.order[index - 1]
	return data.best[previous] ~= nil
end

local function totalPoints(data): number
	local total = 0
	for _, caseId in CaseCatalog.order do
		local best = data.best[caseId]
		if best then
			total += Ranks.GradePoints[best.grade] or 0
		end
	end
	return total
end

local function summary(player: Player)
	local profile = DataService.get(player)
	local data = profile and profile.data or { best = {}, seen = {} }
	local cases = {}
	for _, caseId in CaseCatalog.order do
		cases[caseId] = {
			unlocked = isUnlocked(data, caseId),
			best = data.best[caseId],
		}
	end
	local points = totalPoints(data)
	local nextTitle, nextPoints = Ranks.nextTitle(points)
	return {
		saving = DataService.isSaving(player),
		points = points,
		title = Ranks.titleFor(points),
		nextTitle = nextTitle,
		nextPoints = nextPoints,
		cases = cases,
	}
end

local function sanitized(caseId: string)
	local cached = sanitizedCache[caseId]
	if not cached then
		cached = CaseLogic.sanitize(CASES[caseId])
		sanitizedCache[caseId] = cached
	end
	return cached
end

local function onGetProfile(player: Player)
	DataService.waitFor(player)
	return summary(player)
end

local function onStartCase(player: Player, caseId: any)
	if rateLimited(player) then
		return { ok = false, reason = "busy" }
	end
	if type(caseId) ~= "string" or not CASES[caseId] then
		return { ok = false, reason = "unknown_case" }
	end
	local profile = DataService.waitFor(player)
	if not profile then
		return { ok = false, reason = "no_profile" }
	end
	if not isUnlocked(profile.data, caseId) then
		return { ok = false, reason = "locked" }
	end

	sessions[player] = CaseLogic.newSession(CASES[caseId])
	profile.data.plays += 1

	local seen = {}
	local prefix = caseId .. ":"
	for key in profile.data.seen do
		if string.sub(key, 1, #prefix) == prefix then
			table.insert(seen, string.sub(key, #prefix + 1))
		end
	end

	return {
		ok = true,
		case = sanitized(caseId),
		seen = seen,
		completedBefore = profile.data.best[caseId] ~= nil,
	}
end

local SEEN_TYPES = { dialogue = true, interview = true }

local function onSubmit(player: Player, caseId: any, stepIndex: any, answer: any)
	if rateLimited(player) then
		return { ok = false, reason = "busy" }
	end
	local session = sessions[player]
	if not session or session.caseId ~= caseId then
		return { ok = false, reason = "no_session" }
	end
	local case = CASES[session.caseId]
	local step = case.steps[stepIndex]

	local result = CaseLogic.submit(case, session, stepIndex, answer)
	if not result.ok then
		return result
	end

	local profile = DataService.get(player)
	if profile and step and result.correct and SEEN_TYPES[step.type] then
		local key = case.id .. ":" .. step.id
		if not profile.data.seen[key] then
			profile.data.seen[key] = true
			profile.dirty = true
		end
	end

	if result.finished then
		sessions[player] = nil
		local outcome = result.results
		local before = profile and summary(player) or nil
		local improved = false
		if profile then
			local best = profile.data.best[case.id]
			if not best or outcome.score > best.score then
				profile.data.best[case.id] = {
					score = outcome.score,
					maxScore = outcome.maxScore,
					grade = outcome.grade,
					percent = outcome.percent,
				}
				improved = true
				profile.dirty = true
			end
			task.spawn(DataService.save, player)
		end
		local after = summary(player)
		outcome.improved = improved
		outcome.pointsEarned = after.points - (before and before.points or 0)
		outcome.profile = after
		outcome.saved = after.saving

		-- Newly unlocked case, if any.
		local index = CaseCatalog.indexOf(case.id)
		local nextId = index and CaseCatalog.order[index + 1]
		if nextId and before and not before.cases[nextId].unlocked and after.cases[nextId].unlocked then
			outcome.unlocked = nextId
		end
		outcome.rankUp = before ~= nil and before.title ~= after.title and after.title or nil
	end

	return result
end

local function onAbandon(player: Player)
	sessions[player] = nil
	return true
end

function CaseService.start()
	Net.fn("GetProfile").OnServerInvoke = onGetProfile
	Net.fn("StartCase").OnServerInvoke = onStartCase
	Net.fn("Submit").OnServerInvoke = onSubmit
	Net.fn("AbandonCase").OnServerInvoke = onAbandon

	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
		lastCall[player] = nil
	end)

	-- Catch authoring mistakes at server start (shows in the Output window).
	for id, case in CASES do
		for _, problem in CaseLogic.validate(case) do
			warn("[FirstChair] Case data problem in " .. id .. ": " .. problem)
		end
	end
end

return CaseService
