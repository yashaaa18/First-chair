--[[
	Test suite for FIRST CHAIR's engine-free server logic.
	Run:  luau tests/run.luau        (from the repo root)

	Plays every case start-to-finish against the real server rules, checks the
	answer keys never leak to the client, and exercises scoring/penalties.
]]

local CaseLogic = require("../src/server/CaseLogic")
local Cases = {
	require("../src/server/Cases/Case1"),
	require("../src/server/Cases/Case2"),
	require("../src/server/Cases/Case3"),
}

local passed, failed = 0, 0
local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
		print("  ok   " .. name)
	else
		failed += 1
		print("  FAIL " .. name .. "\n       " .. tostring(err))
	end
end

local function expect(cond: any, msg: string?)
	if not cond then
		error(msg or "expectation failed", 2)
	end
end

local function eq(a: any, b: any, msg: string?)
	if a ~= b then
		error(("%s (expected %s, got %s)"):format(msg or "values differ", tostring(b), tostring(a)), 2)
	end
end

-- The correct answer for any scored step (derived from the server's key).
local function solve(step): any
	if step.type == "choice" then
		for i, o in step.options do
			if o.correct then
				return i
			end
		end
	elseif step.type == "present" then
		return if type(step.answer) == "table" then step.answer[1] else step.answer
	elseif step.type == "testimony" then
		return { statement = step.answers[1].statement, evidence = step.answers[1].evidence }
	elseif step.type == "combine" then
		return { step.answer[2], step.answer[1] } -- order shouldn't matter
	elseif step.type == "order" then
		return table.clone(step.answer)
	end
	return nil
end

-- A plausible wrong answer for a scored step.
local function wrong(case, session, step): any
	if step.type == "choice" then
		for i, o in step.options do
			if not o.correct then
				return i
			end
		end
	elseif step.type == "present" then
		for id in session.inventory do
			local accepted = step.answer
			if id ~= accepted and not (type(accepted) == "table" and table.find(accepted, id)) then
				return id
			end
		end
	elseif step.type == "testimony" then
		-- a pairing that is neither an answer nor a no-penalty hint
		for s = 1, #step.statements do
			for id in session.inventory do
				local isAnswer = false
				for _, a in step.answers do
					if a.statement == s and a.evidence == id then
						isAnswer = true
					end
				end
				local isFreeHint = false
				for _, h in step.hints or {} do
					if
						h.noPenalty
						and (h.statement == nil or h.statement == s)
						and (h.evidence == nil or h.evidence == id)
					then
						isFreeHint = true
					end
				end
				if not isAnswer and not isFreeHint then
					return { statement = s, evidence = id }
				end
			end
		end
	elseif step.type == "combine" then
		local owned = {}
		for id in session.inventory do
			table.insert(owned, id)
		end
		table.sort(owned)
		for i = 1, #owned do
			for j = i + 1, #owned do
				local a, b = owned[i], owned[j]
				local isAnswer = (step.answer[1] == a and step.answer[2] == b)
					or (step.answer[1] == b and step.answer[2] == a)
				local isFree = false
				for _, h in step.hints or {} do
					if h.noPenalty and table.find(h.pair, a) and table.find(h.pair, b) then
						isFree = true
					end
				end
				if not isAnswer and not isFree then
					return { a, b }
				end
			end
		end
	elseif step.type == "order" then
		local a = table.clone(step.answer)
		a[1], a[2] = a[2], a[1]
		return a
	end
	return nil
end

local function play(case, opts: { mistakes: boolean? }?)
	local session = CaseLogic.newSession(case)
	local final = nil
	local guard = 0
	while not session.finished do
		guard += 1
		assert(guard < 500, "playthrough did not terminate")
		local index = session.step
		local step = case.steps[index]
		if CaseLogic.SCORED[step.type] and opts and opts.mistakes then
			local bad = wrong(case, session, step)
			assert(bad ~= nil, "could not build a wrong answer for " .. step.id)
			local r = CaseLogic.submit(case, session, index, bad)
			assert(r.ok and r.correct == false, "wrong answer accepted at " .. step.id)
			assert(type(r.feedback) == "string" and #r.feedback > 0, "no feedback at " .. step.id)
			assert(session.step == index, "wrong answer advanced the case at " .. step.id)
		end
		local r = CaseLogic.submit(case, session, index, solve(step))
		assert(r.ok and r.correct, ("correct answer rejected at %s (%s)"):format(step.id, tostring(r.reason)))
		if r.finished then
			final = r.results
		end
	end
	return final, session
end

local SECRET = {
	correct = true,
	answer = true,
	answers = true,
	feedback = true,
	hints = true,
	wrongFeedback = true,
	positionFeedback = true,
	result = true,
}
local function findSecret(t: any, path: string): string?
	if type(t) ~= "table" then
		return nil
	end
	for k, v in t do
		if SECRET[k] then
			return path .. "." .. tostring(k)
		end
		local found = findSecret(v, path .. "." .. tostring(k))
		if found then
			return found
		end
	end
	return nil
end

print("FIRST CHAIR — logic tests")

for _, case in Cases do
	test(case.id .. ": authored data is valid", function()
		local problems = CaseLogic.validate(case)
		expect(#problems == 0, table.concat(problems, "\n       "))
	end)

	test(case.id .. ": sanitized copy leaks no answers or hidden evidence", function()
		local clean = CaseLogic.sanitize(case)
		local leak = findSecret(clean, case.id)
		expect(leak == nil, "secret field leaked: " .. tostring(leak))
		for id, def in case.evidence do
			if def.hidden then
				expect(clean.evidence[id] == nil, "hidden evidence sent to client: " .. id)
			end
		end
		eq(#clean.steps, #case.steps, "step count")
	end)

	test(case.id .. ": perfect playthrough earns an S", function()
		local results = play(case)
		expect(results, "no results")
		eq(results.score, results.maxScore, "score")
		eq(results.grade, "S", "grade")
		eq(results.mistakes, 0, "mistakes")
	end)

	test(case.id .. ": one mistake per question is penalised but still completes", function()
		local results = play(case, { mistakes = true })
		expect(results, "no results")
		eq(results.mistakes, results.scoredSteps, "mistakes")
		eq(results.score, results.scoredSteps * CaseLogic.pointsForTries(2), "score")
		expect(results.grade ~= "S", "grade should drop")
	end)

	test(case.id .. ": rejects out-of-order and forged submissions", function()
		local session = CaseLogic.newSession(case)
		local r = CaseLogic.submit(case, session, 5, nil)
		expect(not r.ok and r.reason == "out_of_sync", "skipping ahead should fail")
		eq(r.step, 1, "server reports true position")
		r = CaseLogic.submit(case, session, "1", nil)
		expect(not r.ok, "non-number index should fail")
		-- advance to the first evidence-based step and present something not owned
		local idx
		for i, step in case.steps do
			if step.type == "present" or step.type == "testimony" or step.type == "combine" then
				idx = i
				break
			end
		end
		while session.step < idx do
			local s = case.steps[session.step]
			CaseLogic.submit(case, session, session.step, solve(s))
		end
		local step = case.steps[idx]
		local forged: any = if step.type == "present"
			then "not_real"
			elseif step.type == "testimony" then { statement = 1, evidence = "not_real" }
			else { "not_real", "also_fake" }
		r = CaseLogic.submit(case, session, idx, forged)
		expect(not r.ok and r.reason == "invalid", "unowned evidence must be rejected")
		eq(session.tries[step.id], nil, "invalid submissions cost nothing")
	end)
end

test("no-penalty hints do not cost points", function()
	local case = Cases[1]
	local session = CaseLogic.newSession(case)
	local crossIndex
	for i, step in case.steps do
		if step.id == "cross" then
			crossIndex = i
		end
	end
	while session.step < crossIndex do
		CaseLogic.submit(case, session, session.step, solve(case.steps[session.step]))
	end
	local r = CaseLogic.submit(case, session, crossIndex, { statement = 4, evidence = "metadata" })
	expect(r.ok and r.correct == false and r.noPenalty, "hint should be returned without penalty")
	eq(session.tries.cross, nil, "no try recorded")
end)

test("finished sessions accept nothing more", function()
	local case = Cases[1]
	local _, session = play(case)
	local r = CaseLogic.submit(case, session, session.step, nil)
	expect(not r.ok and r.reason == "finished")
end)

test("grades and points", function()
	eq(CaseLogic.gradeFor(100), "S")
	eq(CaseLogic.gradeFor(95), "S")
	eq(CaseLogic.gradeFor(94), "A")
	eq(CaseLogic.gradeFor(60), "B")
	eq(CaseLogic.gradeFor(59), "C")
	eq(CaseLogic.pointsForTries(1), 100)
	eq(CaseLogic.pointsForTries(9), 20)
end)

test("every case has 5+ scored decisions and a Crestline thread", function()
	for _, case in Cases do
		local scored, crestline = 0, false
		for _, step in case.steps do
			if CaseLogic.SCORED[step.type] then
				scored += 1
			end
			for _, line in step.lines or {} do
				if string.find(line[2], "Crestline") then
					crestline = true
				end
			end
		end
		expect(scored >= 5, case.id .. " has only " .. scored .. " decisions")
		expect(crestline, case.id .. " never mentions Crestline")
	end
end)

print(("\n%d passed, %d failed"):format(passed, failed))
if failed > 0 then
	error("tests failed")
end
