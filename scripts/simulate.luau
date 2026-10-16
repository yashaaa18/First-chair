--[[
	simulate.luau — a headless "robot player" for FIRST CHAIR.

	Loads the REAL client and server scripts from the built place file and runs
	them together outside Roblox (with Lune), with a fake network between them.
	A driver then plays through every case by "tapping" the real UI buttons:
	menu -> dialogue -> interviews -> evidence -> testimony -> verdict -> results.
	It deliberately answers some questions wrong first to exercise feedback/retry.

	What this proves: the game logic, UI flow, remotes, scoring, unlocks and every
	property the UI code sets are valid. What it does NOT prove: rendering, real
	physics, animation playback, or how it looks — that needs Roblox itself.

	Run:  lune run scripts/simulate.luau build/FirstChair.rbxlx
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local realTask = require("@lune/task")

local SCALE = 0.01 -- run engine time 100x faster
local path = process.args[1] or "build/FirstChair.rbxlx"
local realGame = roblox.deserializePlace(fs.readFile(path))
local RealInstance = roblox.Instance

----------------------------------------------------------------- scaled task library
local task = {
	wait = function(t)
		realTask.wait((t or 0) * SCALE)
		return t or 0
	end,
	delay = function(t, f, ...)
		return realTask.delay((t or 0) * SCALE, f, ...)
	end,
	spawn = realTask.spawn,
	defer = realTask.defer,
	cancel = realTask.cancel,
}

----------------------------------------------------------------- signals
local Signal = {}
Signal.__index = Signal
function Signal.new(name)
	return setmetatable({ name = name, handlers = {}, waiting = {} }, Signal)
end
function Signal:Connect(fn)
	local entry = { fn = fn, connected = true }
	table.insert(self.handlers, entry)
	return {
		Connected = true,
		Disconnect = function()
			entry.connected = false
		end,
	}
end
function Signal:Once(fn)
	local conn
	conn = self:Connect(function(...)
		conn.Disconnect()
		fn(...)
	end)
	return conn
end
function Signal:Wait()
	table.insert(self.waiting, coroutine.running())
	return coroutine.yield()
end
function Signal:Fire(...)
	for _, entry in table.clone(self.handlers) do
		if entry.connected then
			task.spawn(entry.fn, ...)
		end
	end
	local waiting = self.waiting
	self.waiting = {}
	for _, thread in waiting do
		task.spawn(thread, ...)
	end
end

----------------------------------------------------------------- instance proxies
local proxyOf = {} -- id -> proxy
local realOf = setmetatable({}, { __mode = "k" }) -- proxy -> real
local signalsOf = {} -- id -> { [name] = Signal }
local nextId = 0
local errors = {}
local wrap

local function idOf(inst)
	local id = inst:GetAttribute("__sim")
	if not id then
		nextId += 1
		id = nextId
		inst:SetAttribute("__sim", id)
	end
	return id
end

local function signalFor(inst, name)
	local id = idOf(inst)
	signalsOf[id] = signalsOf[id] or {}
	local s = signalsOf[id][name]
	if not s then
		s = Signal.new(name)
		signalsOf[id][name] = s
	end
	return s
end

local function unwrap(v)
	if type(v) == "table" and realOf[v] then
		return realOf[v]
	end
	return v
end

-- Engine features Lune doesn't implement: harmless no-ops.
local Callable = setmetatable({}, {
	__call = function()
		return nil
	end,
	__index = function()
		return function() end
	end,
})

local METHODS = {
	FindFirstChild = true,
	FindFirstChildOfClass = true,
	FindFirstChildWhichIsA = true,
	FindFirstAncestorOfClass = true,
	GetChildren = true,
	GetDescendants = true,
	ClearAllChildren = true,
	IsA = true,
	GetAttribute = true,
	GetFullName = true,
	IsDescendantOf = true,
}

local function wrapResult(...)
	local out = table.pack(...)
	for i = 1, out.n do
		local v = out[i]
		if typeof(v) == "Instance" then
			out[i] = wrap(v)
		elseif type(v) == "table" then
			local copy = {}
			for k, item in v do
				copy[k] = if typeof(item) == "Instance" then wrap(item) else item
			end
			out[i] = copy
		end
	end
	return table.unpack(out, 1, out.n)
end

local overrides = {} -- id -> { key -> value } for read-only engine props

function wrap(inst)
	if inst == nil or typeof(inst) ~= "Instance" then
		return inst
	end
	local id = idOf(inst)
	local existing = proxyOf[id]
	if existing then
		return existing
	end
	local proxy = {}
	realOf[proxy] = inst
	proxyOf[id] = proxy
	setmetatable(proxy, {
		__index = function(_, key)
			local o = overrides[id]
			if o and o[key] ~= nil then
				return o[key]
			end
			if METHODS[key] then
				return function(_, ...)
					local args = table.pack(...)
					for i = 1, args.n do
						args[i] = unwrap(args[i])
					end
					local real = inst :: any
					return wrapResult(real[key](real, table.unpack(args, 1, args.n)))
				end
			elseif key == "Clone" then
				return function()
					local copy = inst:Clone()
					copy:SetAttribute("__sim", nil)
					for _, d in copy:GetDescendants() do
						d:SetAttribute("__sim", nil)
					end
					return wrap(copy)
				end
			elseif key == "WaitForChild" then
				return function(_, name)
					return wrap(inst:FindFirstChild(name))
				end
			elseif key == "Destroy" then
				return function()
					signalFor(inst, "Destroying"):Fire()
					inst:Destroy()
				end
			elseif key == "SetAttribute" then
				return function(_, name, value)
					inst:SetAttribute(name, value)
					signalFor(inst, "Attr:" .. name):Fire()
				end
			elseif key == "GetAttributeChangedSignal" then
				return function(_, name)
					return signalFor(inst, "Attr:" .. name)
				end
			elseif key == "GetPropertyChangedSignal" then
				return function(_, name)
					return signalFor(inst, "Prop:" .. name)
				end
			end
			if key == "Position" and inst:IsA("BasePart") then
				return inst.CFrame.Position -- derived property Lune doesn't model
			end
			local ok, value = pcall(function()
				return (inst :: any)[key]
			end)
			if ok then
				return wrap(value)
			end
			if string.find(tostring(value), "destroyed") then
				return nil -- Roblox returns nil for a destroyed instance's Parent
			end
			local child = inst:FindFirstChild(key)
			if child then
				return wrap(child)
			end
			-- Events (Activated, Completed, ...) and unimplemented methods.
			local s = signalFor(inst, key)
			return setmetatable({}, {
				__index = function(_, k)
					local member = (s :: any)[k]
					if type(member) == "function" then
						return function(_, ...)
							return member(s, ...)
						end
					end
					return member
				end,
				__call = function()
					return nil
				end,
			})
		end,
		__newindex = function(_, key, value)
			local ok, err = pcall(function()
				(inst :: any)[key] = unwrap(value)
			end)
			if not ok then
				local msg = ("%s.%s = %s  ->  %s"):format(
					inst.ClassName,
					tostring(key),
					tostring(value),
					tostring(err)
				)
				if
					not string.find(msg, "read%-only")
					and not string.find(msg, "not scriptable")
					and not string.find(msg, "destroyed")
				then
					table.insert(errors, msg)
					print("[property error] " .. msg)
				end
				if process.env.SIM_VERBOSE then
					print("[ignored] " .. msg)
				end
				overrides[id] = overrides[id] or {}
				overrides[id][key] = value
			end
		end,
	})
	return proxy
end

----------------------------------------------------------------- fake services
local fakeInstanceLib = {
	new = function(className, parent)
		local inst = wrap(RealInstance.new(className))
		if parent then
			inst.Parent = parent
		end
		return inst
	end,
}

local heartbeat = Signal.new("Heartbeat")
local renderStepped = Signal.new("RenderStepped")

local function makeTweenService()
	return {
		Create = function(_, inst, info, props)
			local completed = Signal.new("Completed")
			local tween = { Completed = completed, PlaybackState = "Begin" }
			function tween:Play()
				for k, v in props do
					inst[k] = v
				end
				task.delay(info.Time or 0, function()
					completed:Fire("Completed")
				end)
			end
			function tween:Cancel()
				completed:Fire("Cancelled")
			end
			return tween
		end,
	}
end

local TweenInfo = {
	new = function(time, style, direction)
		return { Time = time or 1, EasingStyle = style, EasingDirection = direction }
	end,
}

-- Players: one fake local player with a simple character.
local playerGui = wrap(RealInstance.new("Folder"))
playerGui.Name = "PlayerGui"
local playerScripts = wrap(RealInstance.new("Folder"))
local function makeCharacter()
	local model = wrap(RealInstance.new("Model"))
	model.Name = "Tester"
	local humanoid = wrap(RealInstance.new("Humanoid"))
	humanoid.Parent = model
	for _, name in { "HumanoidRootPart", "Head" } do
		local p = wrap(RealInstance.new("Part"))
		p.Name = name
		p.Parent = model
	end
	model.Parent = wrap(realGame:GetService("Workspace"))
	return model
end
local character = makeCharacter()
local localPlayer = {
	Name = "Tester",
	DisplayName = "Tester",
	UserId = 1,
	Character = character,
	CharacterAdded = Signal.new("CharacterAdded"),
	Parent = true,
	WaitForChild = function(self, name)
		if name == "PlayerGui" then
			return playerGui
		elseif name == "PlayerScripts" then
			return playerScripts
		end
		return nil
	end,
}
local fakePlayers = {
	LocalPlayer = localPlayer,
	PlayerAdded = Signal.new("PlayerAdded"),
	PlayerRemoving = Signal.new("PlayerRemoving"),
	GetPlayers = function()
		return { localPlayer }
	end,
	CreateHumanoidModelFromDescription = function()
		error("not available in simulation")
	end,
}

local camera = wrap(RealInstance.new("Camera"))
overrides[idOf(realOf[camera])] = { ViewportSize = roblox.Vector3 and nil }
overrides[idOf(realOf[camera])].ViewportSize = { X = 1180, Y = 820 }

local realWorkspace = wrap(realGame:GetService("Workspace"))
local workspaceProxy = setmetatable({}, {
	__index = function(_, key)
		if key == "CurrentCamera" then
			return camera
		end
		return realWorkspace[key]
	end,
	__newindex = function(_, key, value)
		realWorkspace[key] = value
	end,
})
realOf[workspaceProxy] = realOf[realWorkspace]

local function makeGame(isServer: boolean)
	local services = {
		Players = fakePlayers,
		TweenService = makeTweenService(),
		RunService = {
			IsServer = function()
				return isServer
			end,
			IsClient = function()
				return not isServer
			end,
			IsStudio = function()
				return true
			end,
			Heartbeat = heartbeat,
			RenderStepped = renderStepped,
		},
		UserInputService = { InputBegan = Signal.new("InputBegan"), TouchEnabled = true },
		DataStoreService = {
			GetDataStore = function()
				error("DataStores unavailable in simulation")
			end,
		},
		Workspace = workspaceProxy,
	}
	return {
		GetService = function(_, name)
			if services[name] then
				return services[name]
			end
			return wrap(realGame:GetService(name))
		end,
		BindToClose = function() end,
	}
end

----------------------------------------------------------------- module loader
local function loadScript(scriptInstance, gameProxy, overridesByName)
	local cache = {}
	local function req(target)
		local real = unwrap(target)
		local key = real:GetFullName()
		if overridesByName and overridesByName[real.Name] then
			return overridesByName[real.Name]
		end
		if cache[key] ~= nil then
			return cache[key]
		end
		local env = {
			script = wrap(real),
			game = gameProxy,
			workspace = workspaceProxy,
			require = req,
			task = task,
			Instance = fakeInstanceLib,
			TweenInfo = TweenInfo,
			print = function() end,
			warn = function(...)
				print("[game warn]", ...)
			end,
			typeof = function(v)
				if type(v) == "table" and realOf[v] then
					return "Instance"
				end
				return typeof(v)
			end,
		}
		for name, value in roblox do
			if env[name] == nil then
				env[name] = value
			end
		end
		setmetatable(env, { __index = _G })
		local chunk = luau.load(real.Source, { debugName = key, environment = env })
		local result = chunk()
		cache[key] = result
		return result
	end
	return req, function()
		return req(scriptInstance)
	end
end

----------------------------------------------------------------- server side
local remotes = {} -- name -> handler
local events = {} -- name -> client handlers
local fakeNet = {
	init = function() end,
	fn = function(name)
		return setmetatable({}, {
			__newindex = function(_, key, value)
				if key == "OnServerInvoke" then
					remotes[name] = value
				end
			end,
			__index = function(_, key)
				if key == "InvokeServer" then
					return function(_, ...)
						local handler = remotes[name]
						assert(handler, "no server handler for " .. name)
						-- simulate the network: arguments and results are copied
						local args = table.pack(...)
						local function copy(v)
							if type(v) ~= "table" then
								return v
							end
							local out = {}
							for k, item in v do
								out[k] = copy(item)
							end
							return out
						end
						for i = 1, args.n do
							args[i] = copy(args[i])
						end
						task.wait(0.02)
						return copy(handler(localPlayer, table.unpack(args, 1, args.n)))
					end
				end
				return nil
			end,
		})
	end,
	event = function(name)
		events[name] = events[name] or Signal.new(name)
		local s = events[name]
		return {
			OnClientEvent = s,
			FireClient = function(_, _player, ...)
				s:Fire(...)
			end,
		}
	end,
}

local serverGame = makeGame(true)
local serverScript = realGame:GetService("ServerScriptService"):FindFirstChild("Server")
local serverReq = loadScript(serverScript, serverGame, { Net = fakeNet })
local Cast = serverReq(serverScript:FindFirstChild("World"):FindFirstChild("Cast"))
Cast.build()
local DataService = serverReq(serverScript:FindFirstChild("DataService"))
local CaseService = serverReq(serverScript:FindFirstChild("CaseService"))
local CaseLogic = serverReq(serverScript:FindFirstChild("CaseLogic"))
local Cases = {
	case1 = serverReq(serverScript:FindFirstChild("Cases"):FindFirstChild("Case1")),
	case2 = serverReq(serverScript:FindFirstChild("Cases"):FindFirstChild("Case2")),
	case3 = serverReq(serverScript:FindFirstChild("Cases"):FindFirstChild("Case3")),
}
DataService.load(localPlayer)
CaseService.start()

-- Peek at the server's live session (only the test driver does this).
local currentCase: string? = nil
local stepIndex = 1
local originalSubmit = remotes.Submit
remotes.Submit = function(player, caseId, index, answer)
	currentCase = caseId
	local result = originalSubmit(player, caseId, index, answer)
	if result and result.ok and result.correct then
		stepIndex = result.next or stepIndex
	end
	return result
end
local originalStart = remotes.StartCase
remotes.StartCase = function(player, caseId)
	currentCase = caseId
	stepIndex = 1
	return originalStart(player, caseId)
end

----------------------------------------------------------------- client side
local clientGame = makeGame(false)
local clientScript =
	realGame:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"):FindFirstChild("Client")
local _clientReq, runClient = loadScript(clientScript, clientGame, { Net = fakeNet })
-- PlayerModule stand-in so "disable movement" has something to call
local playerModule = wrap(RealInstance.new("ModuleScript"))
playerModule.Name = "PlayerModule"

task.spawn(function()
	local ok, err = pcall(runClient)
	if not ok then
		table.insert(errors, "client crashed: " .. tostring(err))
		print("[client crash]", err)
	end
end)

-- engine heartbeat
task.spawn(function()
	while true do
		realTask.wait(0.005)
		heartbeat:Fire(1 / 60)
		renderStepped:Fire(1 / 60)
	end
end)

----------------------------------------------------------------- driver helpers
local function find(root, predicate)
	for _, d in realOf[root]:GetDescendants() do
		if predicate(d) then
			return wrap(d)
		end
	end
	return nil
end

local function named(name)
	return find(playerGui, function(d)
		return d.Name == name
	end)
end

local function buttonWithText(root, text)
	return find(root, function(d)
		return d:IsA("TextButton") and d.Text == text
	end)
end

local function tap(button)
	assert(button, "tap: button missing")
	signalFor(realOf[button], "MouseButton1Down"):Fire()
	signalFor(realOf[button], "MouseButton1Up"):Fire()
	signalFor(realOf[button], "Activated"):Fire()
	realTask.wait(0.03)
end

local function waitFor(fn, label, timeout)
	local deadline = os.clock() + (timeout or 20)
	while os.clock() < deadline do
		local v = fn()
		if v then
			return v
		end
		realTask.wait(0.01)
	end
	error("timed out waiting for " .. label)
end

local log = {}
local function note(msg)
	table.insert(log, msg)
	print("  · " .. msg)
end

----------------------------------------------------------------- the robot player
local triedWrong: { [string]: boolean } = {}
local stats = { wrongTried = 0, dialogues = 0, inspected = 0 }

local function currentStep()
	return Cases[currentCase].steps[stepIndex]
end

local function wrongChoiceIndex(step)
	for i, o in step.options do
		if not o.correct then
			return i
		end
	end
end

local function correctChoiceIndex(step)
	for i, o in step.options do
		if o.correct then
			return i
		end
	end
end

local function pickCards(modal, ids, confirmText)
	for _, id in ids do
		local card = find(modal, function(d)
			return d:IsA("TextButton") and d.Name == id
		end)
		assert(card, "evidence card not on screen: " .. id)
		tap(card)
	end
	tap(buttonWithText(modal, confirmText))
end

local function act(): boolean
	local step = currentCase and currentStep()

	-- Results screen
	local results = named("Results")
	if results then
		local nextButton = buttonWithText(results, "Next Case  ›")
		if nextButton then
			note("results: tapping Next Case")
			tap(nextButton)
		else
			note("results: back to Main Menu")
			tap(buttonWithText(results, "Main Menu"))
			return false -- finished all cases
		end
		return true
	end

	-- Verdict banner
	local verdict = named("Verdict")
	if verdict then
		realTask.wait(0.05)
		tap(verdict)
		return true
	end

	-- Inspector open (from review/picker): close it
	local inspector = named("Inspector")
	if inspector then
		tap(buttonWithText(inspector, "Close"))
		return true
	end

	-- Main menu
	local menu = named("MainMenu")
	if menu then
		local select = find(menu, function(d)
			return d.Name == "CaseSelect"
		end)
		if select and select.Visible then
			local begin = buttonWithText(select, "Begin") or buttonWithText(select, "Replay")
			note("menu: choosing a case")
			tap(begin)
		else
			local start = buttonWithText(menu, "Start Game") or buttonWithText(menu, "Continue")
			if start then
				note("menu: Start Game")
				tap(start)
			end
		end
		return true
	end

	-- Choice card
	local choice = named("Choice")
	if choice and step and step.type == "choice" then
		local index = correctChoiceIndex(step)
		if not triedWrong[currentCase .. step.id] then
			triedWrong[currentCase .. step.id] = true
			index = wrongChoiceIndex(step)
			stats.wrongTried += 1
		end
		local button = find(choice, function(d)
			return d:IsA("TextButton") and d.LayoutOrder == 10 + index
		end)
		tap(button)
		return true
	end

	-- Interview menu
	local interview = named("Interview")
	if interview then
		local topic = find(interview, function(d)
			return d:IsA("TextButton")
				and d.LayoutOrder >= 1
				and d.LayoutOrder < 100
				and string.sub(d.Text, 1, 3) ~= "✓"
		end)
		if topic then
			tap(topic)
		else
			tap(buttonWithText(interview, "Continue"))
		end
		return true
	end

	-- Evidence modals (review, picker, order)
	local modal = named("EvidenceModal")
	if modal and step then
		if step.type == "evidence_review" then
			for _, id in step.items do
				local card = find(modal, function(d)
					return d:IsA("TextButton") and d.Name == id
				end)
				assert(card, "review card missing: " .. id)
				tap(card)
				local insp = waitFor(function()
					return named("Inspector")
				end, "inspector")
				stats.inspected += 1
				tap(buttonWithText(insp, "Close"))
				waitFor(function()
					return named("Inspector") == nil
				end, "inspector close")
			end
			tap(buttonWithText(modal, "Continue"))
		elseif step.type == "present" then
			local answer = if type(step.answer) == "table" then step.answer[1] else step.answer
			if not triedWrong[currentCase .. step.id] then
				triedWrong[currentCase .. step.id] = true
				for id in pairs(step.feedback or {}) do
					local exists = find(modal, function(d)
						return d:IsA("TextButton") and d.Name == id
					end)
					if exists then
						answer = id
						stats.wrongTried += 1
						break
					end
				end
			end
			pickCards(modal, { answer }, "Present")
		elseif step.type == "combine" then
			pickCards(modal, step.answer, "Combine")
		elseif step.type == "order" then
			local seq = step.answer
			if not triedWrong[currentCase .. step.id] then
				triedWrong[currentCase .. step.id] = true
				seq = table.clone(step.answer)
				seq[1], seq[2] = seq[2], seq[1]
				stats.wrongTried += 1
			end
			pickCards(modal, seq, "Present")
		elseif step.type == "testimony" then
			local target = step.answers[1]
			pickCards(modal, { target.evidence }, "Present")
		end
		return true
	end

	-- Testimony panel
	local testimony = named("Testimony")
	if testimony and step and step.type == "testimony" and testimony.Visible then
		local target = step.answers[1]
		-- press the first statement once, for coverage
		if not triedWrong[currentCase .. step.id .. "press"] then
			triedWrong[currentCase .. step.id .. "press"] = true
			tap(buttonWithText(testimony, "Press"))
			return true
		end
		for _ = 1, #step.statements + 1 do
			local counter = find(testimony, function(d)
				return d:IsA("TextLabel") and string.find(d.Text, "STATEMENT") ~= nil
			end)
			if counter and string.find(counter.Text, ("STATEMENT %d /"):format(target.statement)) then
				break
			end
			tap(buttonWithText(testimony, "›"))
		end
		tap(buttonWithText(testimony, "Present Evidence"))
		return true
	end

	-- Dialogue: tap to advance
	local catcher = named("TapCatcher")
	if catcher then
		stats.dialogues += 1
		tap(catcher)
		return true
	end

	return true
end

----------------------------------------------------------------- run it
print("FIRST CHAIR — headless simulation")
local finishedCases = {}
local started = os.clock()
local ok, err = pcall(function()
	local idleSince = os.clock()
	while true do
		local before = stepIndex .. tostring(currentCase)
		local keepGoing = act()
		if not keepGoing then
			break
		end
		if currentCase and not finishedCases[currentCase] then
			local session = Cases[currentCase]
			if stepIndex > #session.steps then
				finishedCases[currentCase] = true
			end
		end
		if before ~= stepIndex .. tostring(currentCase) then
			idleSince = os.clock()
		elseif os.clock() - idleSince > 20 then
			error(
				("stuck at %s step %d (%s)"):format(
					tostring(currentCase),
					stepIndex,
					tostring(currentCase and currentStep() and currentStep().type)
				)
			)
		end
		if #errors > 0 then
			error("property errors detected")
		end
		realTask.wait(0.01)
	end
end)

local profile = remotes.GetProfile(localPlayer)
print("")
print(("Cases completed: %s"):format(table.concat(
	(function()
		local list = {}
		for id, best in profile.cases do
			if best.best then
				table.insert(
					list,
					("%s=%s (%d/%d)"):format(id, best.best.grade, best.best.score, best.best.maxScore)
				)
			end
		end
		table.sort(list)
		return list
	end)(),
	", "
)))
print(("Career: %s, %d pts"):format(profile.title, profile.points))
print(
	("Dialogue taps: %d · exhibits inspected: %d · deliberate wrong answers: %d · %.1fs"):format(
		stats.dialogues,
		stats.inspected,
		stats.wrongTried,
		os.clock() - started
	)
)

local allDone = profile.cases.case1.best and profile.cases.case2.best and profile.cases.case3.best
if not ok or #errors > 0 or not allDone then
	print("SIMULATION FAILED: " .. tostring(err))
	for _, e in errors do
		print("  " .. e)
	end
	process.exit(1)
end
print("SIMULATION PASSED")
process.exit(0)
