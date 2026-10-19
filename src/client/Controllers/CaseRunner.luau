--[[
	CaseRunner — plays a case from the server's (answer-free) script.

	For every step it shows the right interface, sends the player's answer to the
	server, and reacts to the server's verdict. The client never decides whether
	an answer is right, what the score is, or what gets unlocked.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local StageLayout = require(Shared.StageLayout)

local Controllers = script.Parent
local UI = Controllers.Parent.UI
local Audio = require(Controllers.Audio)
local CameraDirector = require(Controllers.CameraDirector)
local Music = require(Controllers.Music)
local Stage = require(Controllers.Stage)

local Root = require(UI.Root)
local Transition = require(UI.Transition)
local Feedback = require(UI.Feedback)
local Dialogue = require(UI.Dialogue)
local Choice = require(UI.Choice)
local Evidence = require(UI.Evidence)
local Testimony = require(UI.Testimony)
local Interview = require(UI.Interview)
local Hud = require(UI.Hud)
local PauseMenu = require(UI.PauseMenu)
local Results = require(UI.Results)

local CaseRunner = {}

type Def = Evidence.Def

-- Per-run state
local case = nil
local defs: { [string]: Def } = {}
local inventory: { string } = {}
local seen: { [string]: boolean } = {}
local completedBefore = false
local lastSpeaker: string? = nil
local runToken = 0

local function invoke(name: string, ...: any): any
	local remote = Net.fn(name)
	for attempt = 1, 3 do
		local ok, result = pcall(remote.InvokeServer, remote, ...)
		if ok then
			return result
		end
		warn("[FirstChair] " .. name .. " failed:", result)
		Feedback.toast("Connection hiccup — retrying…", "warning")
		task.wait(attempt)
	end
	return nil
end

local function inventoryDefs(): { Def }
	local list = {}
	for _, id in inventory do
		if defs[id] then
			table.insert(list, defs[id])
		end
	end
	return list
end

local function addEvidence(def: Def, quiet: boolean?)
	defs[def.id] = def
	if not table.find(inventory, def.id) then
		table.insert(inventory, def.id)
		if not quiet then
			Audio.play("gain")
			Feedback.evidenceGained(def.name, if def.kind == "combined" then "NEW COMBINED EVIDENCE" else nil)
		end
	end
	Hud.setEvidenceCount(#inventory)
end

----------------------------------------------------------------- camera helpers
local function focus(speaker: string, force: boolean?)
	if speaker == "narrator" then
		return
	end
	if speaker == lastSpeaker and not force then
		return
	end
	local head, facing, side = Stage.focus(speaker)
	if head and facing then
		lastSpeaker = speaker
		CameraDirector.closeup(head, facing, side)
	end
end

local function playLines(lines, skippable: boolean?)
	return Dialogue.play(lines, {
		skippable = skippable,
		nameOf = Stage.displayName,
		onLine = function(line)
			if line.shot then
				lastSpeaker = nil
				CameraDirector.shot(line.shot)
			else
				focus(line[1])
			end
		end,
	})
end

----------------------------------------------------------------- step handlers
local handlers = {}

function handlers.scene(step)
	Transition.fadeOut(0.28)
	Music.play(step.location)
	Stage.setScene(step)
	lastSpeaker = nil
	local shot = StageLayout.Shots[step.shot]
	if shot then
		CameraDirector.cut(shot.cf, shot.fov)
		-- a gentle settle so every scene opens with movement
		CameraDirector.move(shot.cf * CFrame.new(0, 0, -1.2), shot.fov, 2.4)
	end
	task.wait(0.1)
	Transition.fadeIn(0.4)
	if step.title then
		Transition.locationCard(StageLayout.LocationTitles[step.location] or "", step.title)
		task.wait(0.6)
	end
	return nil
end

function handlers.dialogue(step)
	playLines(step.lines, seen[step.id] or completedBefore)
	return nil
end

function handlers.interview(step)
	local skippable = seen[step.id] or completedBefore
	Interview.run(step, function(lines)
		playLines(lines, skippable)
	end, function()
		focus(step.with, true)
	end)
	return nil
end

function handlers.evidence_review(step)
	local list = {}
	for _, id in step.items do
		if defs[id] then
			table.insert(list, defs[id])
		end
	end
	Evidence.review(list, step.prompt)
	return nil
end

function handlers.gain(_step)
	return nil
end

function handlers.choice(step)
	if step.speaker then
		focus(step.speaker, true)
	end
	local name = step.speaker and (Stage.displayName(step.speaker))
	return Choice.ask(step.prompt, step.options, name)
end

function handlers.present(step)
	if step.speaker then
		focus(step.speaker, true)
	end
	local picked = Evidence.pick(inventoryDefs(), {
		title = "Present Evidence",
		prompt = step.prompt,
		count = 1,
		confirmText = "Present",
	})
	return picked and picked[1]
end

function handlers.combine(step)
	local picked = Evidence.pick(inventoryDefs(), {
		title = "Combine Evidence",
		prompt = step.prompt,
		count = 2,
		confirmText = "Combine",
	})
	return picked
end

function handlers.order(step)
	local list = {}
	for _, id in step.items do
		if defs[id] then
			table.insert(list, defs[id])
		end
	end
	return Evidence.order(list, step.prompt)
end

local testimonyPosition: { [string]: number } = {}
function handlers.testimony(step)
	local answer, position = Testimony.run(step, {
		start = testimonyPosition[step.id],
		onShow = function()
			focus(step.witness)
		end,
		press = function(i)
			local press = step.statements[i].press
			if press then
				playLines(press)
			end
			focus(step.witness, true)
		end,
		present = function(i)
			local picked = Evidence.pick(inventoryDefs(), {
				title = "Present Evidence",
				prompt = "Against: “" .. step.statements[i].text .. "”",
				count = 1,
				confirmText = "Present",
				cancellable = true,
			})
			focus(step.witness, true)
			return picked and picked[1]
		end,
	})
	testimonyPosition[step.id] = position
	return answer
end

function handlers.verdict(step)
	Feedback.verdict(step.title, step.subtitle, function()
		Audio.play("gavel")
		CameraDirector.shake(0.4, 0.3)
	end)
	return nil
end

function handlers.complete(_step)
	return nil
end

----------------------------------------------------------------- reactions
local function onCorrect(step, result)
	if step.type == "testimony" or step.type == "present" then
		Audio.play("objection")
		Stage.gesture("player")
		focus("player", true)
		CameraDirector.shake(0.8, 0.35)
		Feedback.objection(
			"OBJECTION!",
			if step.type == "present" then "The evidence speaks." else "Contradiction found."
		)
	elseif step.type == "combine" then
		Audio.play("confirm")
		Feedback.toast("Evidence combined", "success")
	elseif step.type == "order" then
		Audio.play("objection")
		CameraDirector.shake(0.6, 0.3)
		Feedback.objection("THE TIMELINE", "Every minute accounted for.")
	elseif step.type == "choice" then
		Audio.play("confirm")
		if result.feedback then
			Feedback.toast(result.feedback, "success", 3)
		end
	end
	if result.granted then
		for _, def in result.granted do
			addEvidence(def)
		end
	end
end

local function onWrong(step, result)
	Audio.play("wrong")
	if not result.noPenalty then
		Feedback.toast("Not quite — try again", "danger", 1.6)
	end
	CameraDirector.shake(0.25, 0.2)
	local coach = result.coach or "mara"
	if not Stage.has(coach) then
		coach = "narrator"
	end
	lastSpeaker = nil
	playLines({ { coach, result.feedback } })
	if step.type == "testimony" then
		focus(step.witness, true)
	end
end

----------------------------------------------------------------- main loop
function CaseRunner.run(caseId: string): string
	runToken += 1
	local myToken = runToken
	Root.clearCaseUi()

	local start = invoke("StartCase", caseId)
	if not start or not start.ok then
		Feedback.toast(
			if start and start.reason == "locked"
				then "That case is still locked."
				else "Couldn't open the case. Try again.",
			"danger"
		)
		return "menu"
	end

	case = start.case
	defs = {}
	for id, def in case.evidence do
		defs[id] = def
	end
	inventory = {}
	seen = {}
	for _, id in start.seen do
		seen[id] = true
	end
	completedBefore = start.completedBefore == true
	lastSpeaker = nil
	testimonyPosition = {}

	local outcome: string? = nil
	local caseThread = coroutine.running()

	Hud.show(("Case %d  ·  %s"):format(case.number, case.title), {
		onCaseFile = function()
			Evidence.caseFile(inventoryDefs())
		end,
		onPause = function()
			local choice = PauseMenu.show(case.title, { enabled = Music.isEnabled, toggle = Music.toggle })
			if choice == "restart" or choice == "menu" then
				local quitTo = if choice == "restart" then "replay" else "menu"
				outcome = quitTo
				runToken += 1
				Root.clearCaseUi()
				Hud.hide()
				Stage.clear()
				pcall(task.cancel, caseThread)
				task.spawn(invoke, "AbandonCase")
				-- the cancelled thread can't return, so finish on its behalf
				CaseRunner.finished(quitTo)
			end
		end,
	})
	Hud.setEvidenceCount(0)

	local index = 1
	while index <= #case.steps do
		if myToken ~= runToken then
			return outcome or "menu"
		end
		local step = case.steps[index]
		if step.objective then
			Hud.setObjective(step.objective)
		end
		local handler = handlers[step.type]
		local answer = if handler then handler(step) else nil
		if myToken ~= runToken then
			return outcome or "menu"
		end

		local result = invoke("Submit", case.id, index, answer)
		if myToken ~= runToken then
			return outcome or "menu"
		end
		if not result then
			Feedback.toast("Lost connection to the court. Returning to menu.", "danger", 4)
			Hud.hide()
			return "menu"
		end
		if not result.ok then
			if result.reason == "out_of_sync" and result.step then
				index = result.step
			elseif result.reason == "busy" then
				task.wait(0.5)
			else
				-- invalid input: just let the player try the step again
				Feedback.toast("Let's try that again.", "warning")
			end
			continue
		end

		if result.correct == false then
			onWrong(step, result)
			continue
		end

		onCorrect(step, result)

		if result.finished then
			Hud.hide()
			Stage.clear()
			Music.play("results")
			local choice = Results.show(result.results, case.title, {
				gavel = function()
					Audio.play("gavel")
				end,
				unlock = function()
					Audio.play("unlock")
				end,
			})
			return choice
		end
		index = result.next
	end
	Hud.hide()
	return "menu"
end

-- Set by the main script: called when a case is quit from the pause menu.
CaseRunner.finished = function(_outcome: string) end

return CaseRunner
