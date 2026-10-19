--[[
	FIRST CHAIR — client entry point.
	Sets up camera, stage, music and interface, then loops:
	title screen -> (lobby) -> case -> results -> ...
]]

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local CaseCatalog = require(Shared.CaseCatalog)

local Controllers = script.Controllers
local UI = script.UI
local Audio = require(Controllers.Audio)
local CameraDirector = require(Controllers.CameraDirector)
local Music = require(Controllers.Music)
local Stage = require(Controllers.Stage)
local CaseRunner = require(Controllers.CaseRunner)

local Kit = require(UI.Kit)
local Root = require(UI.Root)
local Feedback = require(UI.Feedback)
local Evidence = require(UI.Evidence)
local MainMenu = require(UI.MainMenu)
local LobbyHud = require(UI.LobbyHud)
local Transition = require(UI.Transition)

-- A focused, story-first screen: hide Roblox's default HUD pieces we don't use.
local function hideCoreUi()
	for _, kind in
		{
			Enum.CoreGuiType.PlayerList,
			Enum.CoreGuiType.Backpack,
			Enum.CoreGuiType.Health,
			Enum.CoreGuiType.EmotesMenu,
		}
	do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(kind, false)
		end)
	end
end

-- Chat is for the lobby and the title screen; a case is a private story.
local function setChat(on: boolean)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, on)
	end)
end

hideCoreUi()
Root.init()
Audio.init()
Music.init()
CameraDirector.init()
Stage.init()
Kit.setClickSound(function()
	Audio.play("click")
end)
Evidence.setSounds(function()
	Audio.play("page")
end, function()
	Audio.play("confirm")
end)

Net.event("Notice").OnClientEvent:Connect(function(notice)
	if type(notice) == "table" and type(notice.text) == "string" then
		Feedback.toast(notice.text, notice.kind or "info", 4)
	end
end)
Net.event("Broadcast").OnClientEvent:Connect(function(notice)
	if type(notice) == "table" and type(notice.text) == "string" then
		Feedback.toast(notice.text, notice.kind or "info", 3.5)
	end
end)

local function getProfile()
	for attempt = 1, 5 do
		local ok, profile = pcall(function()
			return Net.fn("GetProfile"):InvokeServer()
		end)
		if ok and type(profile) == "table" then
			return profile
		end
		task.wait(attempt)
	end
	-- Offline fallback so the menu still renders.
	local cases = {}
	for i, id in CaseCatalog.order do
		cases[id] = { unlocked = i == 1 }
	end
	return { saving = false, points = 0, title = "Junior Associate", streak = 0, cases = cases }
end

-- Run one case on its own thread so "Quit" can stop it cleanly.
local function playCase(caseId: string): string
	return Kit.await(function(resolve)
		CaseRunner.finished = resolve
		task.spawn(function()
			resolve(CaseRunner.run(caseId))
		end)
		return nil
	end)
end

local function showMenuScene()
	Stage.setLobbyMode(false)
	Stage.clear()
	Stage.placePlayer("office_entry")
	CameraDirector.loop("office_menu", "office_menu_end", 16)
	Music.play("menu")
	setChat(true)
end

-- Walk around Valence Legal with everyone else on the server.
local function lobby(profile): string
	Transition.fadeOut(0.25)
	Root.clearCaseUi()
	Stage.setLobbyMode(true)
	CameraDirector.free()
	Music.play("menu")
	setChat(true)
	Transition.fadeIn(0.35)
	local result = LobbyHud.run(profile, function(onTrigger)
		return ProximityPromptService.PromptTriggered:Connect(function(prompt)
			if prompt.Name == "CaseFilesPrompt" then
				onTrigger()
			end
		end)
	end)
	Transition.fadeOut(0.25)
	Stage.setLobbyMode(false)
	return result
end

local nextCase: string? = nil
local startOnSelect = false
while true do
	local caseId = nextCase
	nextCase = nil
	if not caseId then
		local profile = getProfile()
		local pick = MainMenu.run(profile, {
			onShow = showMenuScene,
			musicEnabled = Music.isEnabled,
			onToggleMusic = Music.toggle,
			startOnSelect = startOnSelect,
		})
		startOnSelect = false
		if pick == "__lobby" then
			startOnSelect = lobby(profile) == "cases"
			Transition.fadeIn(0.35)
			continue
		end
		caseId = pick
	end
	setChat(false)
	local outcome = playCase(caseId :: string)
	if outcome == "replay" then
		nextCase = caseId
	elseif outcome == "next" then
		local index = CaseCatalog.indexOf(caseId :: string)
		nextCase = index and CaseCatalog.order[index + 1] or nil
	end
	Transition.fadeOut(0.25)
	Root.clearCaseUi()
	if not nextCase then
		showMenuScene()
	end
	Transition.fadeIn(0.35)
end
