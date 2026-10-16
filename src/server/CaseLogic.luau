--[[
	CaseLogic — pure, engine-free rules for running a case.

	Everything that decides "was that right?", "what's the score?" and "what does
	the player own?" lives here, on the server. It has no Roblox dependencies so the
	test suite can run it with plain Luau (see tests/).

	The client only ever receives a *sanitized* copy of a case (no answers).
]]

local CaseLogic = {}

CaseLogic.SCORED = {
	choice = true,
	present = true,
	testimony = true,
	combine = true,
	order = true,
}

CaseLogic.STEP_TYPES = {
	scene = true,
	dialogue = true,
	interview = true,
	evidence_review = true,
	gain = true,
	choice = true,
	present = true,
	testimony = true,
	combine = true,
	order = true,
	verdict = true,
	complete = true,
}

-- Fields that must never reach the client.
local SECRET_KEYS = {
	correct = true,
	answer = true,
	answers = true,
	feedback = true,
	hints = true,
	wrongFeedback = true,
	positionFeedback = true,
	result = true,
}

-- Step points by attempt number (kept in sync with shared/Ranks.luau).
local STEP_POINTS = { 100, 60, 35 }
local STEP_FLOOR = 20

local function pointsForTries(tries: number): number
	return STEP_POINTS[tries] or STEP_FLOOR
end

local function gradeFor(percent: number): string
	if percent >= 95 then
		return "S"
	elseif percent >= 80 then
		return "A"
	elseif percent >= 60 then
		return "B"
	end
	return "C"
end

CaseLogic.pointsForTries = pointsForTries
CaseLogic.gradeFor = gradeFor

local function deepCopy(value: any, strip: boolean): any
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value do
		if not (strip and SECRET_KEYS[k]) then
			out[k] = deepCopy(v, strip)
		end
	end
	return out
end

-- Public evidence definition (what the player can read about an item).
function CaseLogic.publicEvidence(case, id: string)
	local def = case.evidence[id]
	if not def then
		return nil
	end
	local copy = deepCopy(def, true)
	copy.id = id
	copy.hidden = nil
	return copy
end

-- Strip answer keys and hidden evidence so the case can be sent to a client.
function CaseLogic.sanitize(case)
	local out = {
		id = case.id,
		title = case.title,
		number = case.number,
		evidence = {},
		steps = {},
	}
	for id, def in case.evidence do
		if not def.hidden then
			out.evidence[id] = CaseLogic.publicEvidence(case, id)
		end
	end
	for i, step in case.steps do
		local copy = deepCopy(step, true)
		if step.type == "choice" then
			-- options keep their text only
			copy.options = {}
			for j, option in step.options do
				copy.options[j] = { text = option.text }
			end
		end
		out.steps[i] = copy
	end
	return out
end

function CaseLogic.newSession(case)
	return {
		caseId = case.id,
		step = 1,
		tries = {}, -- [stepId] = attempts used (including the correct one)
		cleared = {}, -- [stepId] = true
		inventory = {}, -- [evidenceId] = true
		finished = false,
	}
end

local function owns(session, id: any): boolean
	return type(id) == "string" and session.inventory[id] == true
end

local function matchesHint(hints, predicate): any
	if type(hints) ~= "table" then
		return nil
	end
	for _, hint in hints do
		if predicate(hint) then
			return hint
		end
	end
	return nil
end

-- Returns status ("correct" | "wrong" | "invalid"), feedback, noPenalty
function CaseLogic.check(case, session, step, answer): (string, string?, boolean?)
	local kind = step.type

	if kind == "choice" then
		if type(answer) ~= "number" or answer % 1 ~= 0 then
			return "invalid"
		end
		local option = step.options[answer]
		if not option then
			return "invalid"
		end
		if option.correct then
			return "correct", option.feedback
		end
		return "wrong", option.feedback or step.wrongFeedback, option.noPenalty
	elseif kind == "present" then
		if not owns(session, answer) then
			return "invalid"
		end
		local accepted = step.answer
		if accepted == answer or (type(accepted) == "table" and table.find(accepted, answer)) then
			return "correct"
		end
		local specific = type(step.feedback) == "table" and step.feedback[answer] or nil
		return "wrong", specific or step.wrongFeedback
	elseif kind == "testimony" then
		if type(answer) ~= "table" then
			return "invalid"
		end
		local statement, evidence = answer.statement, answer.evidence
		if type(statement) ~= "number" or not step.statements[statement] or not owns(session, evidence) then
			return "invalid"
		end
		for _, pair in step.answers do
			if pair.statement == statement and pair.evidence == evidence then
				return "correct"
			end
		end
		local hint = matchesHint(step.hints, function(h)
			return (h.statement == nil or h.statement == statement)
				and (h.evidence == nil or h.evidence == evidence)
		end)
		if hint then
			return "wrong", hint.feedback, hint.noPenalty
		end
		return "wrong", step.wrongFeedback
	elseif kind == "combine" then
		if type(answer) ~= "table" or #answer ~= 2 then
			return "invalid"
		end
		local a, b = answer[1], answer[2]
		if a == b or not owns(session, a) or not owns(session, b) then
			return "invalid"
		end
		local want = step.answer
		if (want[1] == a and want[2] == b) or (want[1] == b and want[2] == a) then
			return "correct"
		end
		local hint = matchesHint(step.hints, function(h)
			return table.find(h.pair, a) ~= nil and table.find(h.pair, b) ~= nil
		end)
		if hint then
			return "wrong", hint.feedback, hint.noPenalty
		end
		return "wrong", step.wrongFeedback
	elseif kind == "order" then
		if type(answer) ~= "table" or #answer ~= #step.answer then
			return "invalid"
		end
		local seen = {}
		for _, id in answer do
			if type(id) ~= "string" or seen[id] or not table.find(step.items, id) then
				return "invalid"
			end
			seen[id] = true
		end
		local firstWrong = nil
		for i, id in step.answer do
			if answer[i] ~= id then
				firstWrong = i
				break
			end
		end
		if not firstWrong then
			return "correct"
		end
		local specific = step.positionFeedback and step.positionFeedback[firstWrong]
		return "wrong", specific or step.wrongFeedback
	end

	return "invalid"
end

-- Items a step hands to the player when it is cleared.
function CaseLogic.grantsFor(step): { string }
	if step.type == "evidence_review" or step.type == "gain" then
		return step.items
	elseif step.type == "combine" then
		return { step.result }
	end
	return {}
end

function CaseLogic.computeResults(case, session)
	local maxScore, score, mistakes, perfect, scoredSteps = 0, 0, 0, 0, 0
	for _, step in case.steps do
		if CaseLogic.SCORED[step.type] then
			scoredSteps += 1
			maxScore += STEP_POINTS[1]
			local tries = session.tries[step.id] or 1
			score += pointsForTries(tries)
			mistakes += math.max(0, tries - 1)
			if tries == 1 then
				perfect += 1
			end
		end
	end
	local percent = if maxScore > 0 then math.floor(score / maxScore * 100 + 0.5) else 100
	return {
		caseId = case.id,
		score = score,
		maxScore = maxScore,
		percent = percent,
		grade = gradeFor(percent),
		mistakes = mistakes,
		perfectSteps = perfect,
		scoredSteps = scoredSteps,
	}
end

--[[
	Submit an answer (or an acknowledgement for unscored steps).
	Returns a result table safe to send to the client.
]]
function CaseLogic.submit(case, session, stepIndex: any, answer: any)
	if session.finished then
		return { ok = false, reason = "finished" }
	end
	if type(stepIndex) ~= "number" or stepIndex ~= session.step then
		return { ok = false, reason = "out_of_sync", step = session.step }
	end
	local step = case.steps[stepIndex]
	if not step then
		return { ok = false, reason = "no_step" }
	end

	if CaseLogic.SCORED[step.type] then
		local status, feedback, noPenalty = CaseLogic.check(case, session, step, answer)
		if status == "invalid" then
			return { ok = false, reason = "invalid" }
		end
		if status == "wrong" then
			if not noPenalty then
				session.tries[step.id] = (session.tries[step.id] or 1) + 1
			end
			return {
				ok = true,
				correct = false,
				feedback = feedback or "That doesn't hold up. Try another angle.",
				coach = step.coach or "mara",
				noPenalty = noPenalty == true,
			}
		end
		session.tries[step.id] = session.tries[step.id] or 1
		session.cleared[step.id] = true
	end

	local granted = {}
	for _, id in CaseLogic.grantsFor(step) do
		if not session.inventory[id] then
			session.inventory[id] = true
			table.insert(granted, CaseLogic.publicEvidence(case, id))
		end
	end

	session.step = stepIndex + 1
	local result = {
		ok = true,
		correct = true,
		next = session.step,
		granted = granted,
	}

	if CaseLogic.SCORED[step.type] then
		result.tries = session.tries[step.id]
		if step.type == "choice" then
			local option = step.options[answer]
			result.feedback = option and option.feedback
		end
	end

	if step.type == "complete" or session.step > #case.steps then
		session.finished = true
		result.finished = true
		result.results = CaseLogic.computeResults(case, session)
	end
	return result
end

-- Static validation of authored case data. Returns a list of problems.
function CaseLogic.validate(case): { string }
	local problems = {}
	local function problem(msg: string)
		table.insert(problems, (case.id or "?") .. ": " .. msg)
	end
	if type(case.evidence) ~= "table" or type(case.steps) ~= "table" then
		problem("missing evidence or steps")
		return problems
	end
	local ids = {}
	local owned = {}
	local last = case.steps[#case.steps]
	if not last or last.type ~= "complete" then
		problem("last step must be 'complete'")
	end
	for i, step in case.steps do
		local where = ("step %d (%s)"):format(i, tostring(step.id))
		if type(step.id) ~= "string" then
			problem(where .. " has no id")
		elseif ids[step.id] then
			problem(where .. " duplicate id")
		end
		ids[step.id or i] = true
		if not CaseLogic.STEP_TYPES[step.type] then
			problem(where .. " unknown type " .. tostring(step.type))
		end
		local function needsOwned(id, label)
			if not case.evidence[id] then
				problem(where .. " " .. label .. " references unknown evidence " .. tostring(id))
			elseif not owned[id] then
				problem(where .. " " .. label .. " uses evidence not yet owned: " .. tostring(id))
			end
		end
		if step.type == "choice" then
			local correct = 0
			for _, o in step.options do
				if o.correct then
					correct += 1
				end
				if type(o.text) ~= "string" then
					problem(where .. " option without text")
				end
				if
					not o.correct
					and type(o.feedback) ~= "string"
					and type(step.wrongFeedback) ~= "string"
				then
					problem(where .. " wrong option without feedback")
				end
			end
			if correct ~= 1 then
				problem(where .. " must have exactly one correct option")
			end
		elseif step.type == "present" then
			local list = type(step.answer) == "table" and step.answer or { step.answer }
			for _, id in list do
				needsOwned(id, "answer")
			end
		elseif step.type == "testimony" then
			if #step.answers == 0 then
				problem(where .. " has no answers")
			end
			for _, pair in step.answers do
				if not step.statements[pair.statement] then
					problem(where .. " answer references missing statement")
				end
				needsOwned(pair.evidence, "answer")
			end
		elseif step.type == "combine" then
			needsOwned(step.answer[1], "combine")
			needsOwned(step.answer[2], "combine")
			if not case.evidence[step.result] then
				problem(where .. " result is unknown evidence")
			end
		elseif step.type == "order" then
			if #step.answer ~= #step.items then
				problem(where .. " answer/items length mismatch")
			end
			for _, id in step.items do
				needsOwned(id, "order item")
			end
		elseif step.type == "evidence_review" or step.type == "gain" then
			for _, id in step.items do
				if not case.evidence[id] then
					problem(where .. " grants unknown evidence " .. tostring(id))
				end
			end
		elseif step.type == "dialogue" then
			if type(step.lines) ~= "table" or #step.lines == 0 then
				problem(where .. " has no lines")
			end
		end
		for _, id in CaseLogic.grantsFor(step) do
			owned[id] = true
		end
	end
	return problems
end

return CaseLogic
