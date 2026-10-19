--[[
	Stage — the player's private set, plus the shared social lobby.

	Case mode: local copies of the cast stand on their marks, the player's avatar is
	parked at its mark, and other players are hidden so a shared server still feels
	like a personal story.

	Lobby mode: the avatar can walk, nearby players are drawn (nearest first, up to a
	budget that keeps iPads smooth in big servers) with their career title over their
	head, and the case board can be tapped to start playing.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StageLayout = require(Shared.StageLayout)
local Characters = require(Shared.Characters)
local Config = require(Shared.Config)

local Stage = {}

local player = Players.LocalPlayer
local IDLE_ANIMATION = "rbxassetid://507766388" -- Roblox's default R15 idle
local POINT_ANIMATION = "rbxassetid://507770453" -- Roblox's default R15 "point" emote

local folder: Folder? = nil
local actors: { [string]: { model: Model, spot: StageLayout.Spot, tracks: { [string]: AnimationTrack } } } =
	{}
local playerSpot: StageLayout.Spot? = nil
local lobbyMode = false
local controls: any = nil

local function stageFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "LocalStage"
	f.Parent = workspace
	folder = f
	return f
end

local function rootOffset(model: Model): number
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid and root and humanoid.RigType == Enum.HumanoidRigType.R15 then
		return humanoid.HipHeight + root.Size.Y / 2
	end
	return 3
end

local function loadTrack(model: Model, id: string, looped: boolean): AnimationTrack?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local ok, track = pcall(function()
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		return (animator :: Animator):LoadAnimation(anim)
	end)
	if ok and track then
		track.Looped = looped
		return track
	end
	return nil
end

local function templates(): Folder?
	return ReplicatedStorage:WaitForChild("FirstChairCast", 20) :: Folder?
end

----------------------------------------------------------------- actors
function Stage.clear()
	for _, actor in actors do
		actor.model:Destroy()
	end
	table.clear(actors)
end

local function spawnActor(characterId: string, spotName: string)
	local spot = StageLayout.Spots[spotName]
	local source = templates()
	local template = source and source:FindFirstChild(characterId) :: Model?
	if not spot or not template then
		warn("[FirstChair] Missing actor or spot:", characterId, spotName)
		return
	end
	local model = template:Clone()
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.Anchored = true
		model.PrimaryPart = root
	end
	model:PivotTo(spot.cf * CFrame.new(0, rootOffset(model), 0))
	model.Parent = stageFolder()
	local tracks = {}
	local idle = loadTrack(model, IDLE_ANIMATION, true)
	if idle then
		idle:Play(0.2, 1, 0.9 + math.random() * 0.2)
		tracks.idle = idle
	end
	actors[characterId] = { model = model, spot = spot, tracks = tracks }
end

----------------------------------------------------------------- own avatar
local function ownHumanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getControls(): any
	if controls then
		return controls
	end
	local ok, result = pcall(function()
		local scripts = player:WaitForChild("PlayerScripts", 10)
		local module = scripts and scripts:WaitForChild("PlayerModule", 10) :: ModuleScript?
		return module and (require(module) :: any):GetControls()
	end)
	if ok and result then
		controls = result
	end
	return controls
end

local function setWalking(enabled: boolean)
	local humanoid = ownHumanoid()
	if humanoid then
		humanoid.WalkSpeed = if enabled then Config.Lobby.walkSpeed else 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.Anchored = not enabled
	end
	local c = getControls()
	if c then
		if enabled then
			c:Enable()
		else
			c:Disable()
		end
	end
end

function Stage.placePlayer(spotName: string?)
	if not spotName then
		return
	end
	local spot = StageLayout.Spots[spotName]
	if not spot then
		return
	end
	playerSpot = spot
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not root then
		return
	end
	root.Anchored = true
	character:PivotTo(spot.cf * CFrame.new(0, rootOffset(character), 0))
end

-- Apply a scene step: { location, cast = { [spot] = characterId }, player = spot }
function Stage.setScene(step)
	Stage.clear()
	for spotName, characterId in step.cast or {} do
		spawnActor(characterId, spotName)
	end
	Stage.placePlayer(step.player)
end

-- Head + facing for a speaker id ("player" or a character id).
function Stage.focus(speaker: string): (BasePart?, CFrame?, number?)
	if speaker == "player" then
		local character = player.Character
		local head = character and character:FindFirstChild("Head") :: BasePart?
		if head and playerSpot then
			return head, playerSpot.cf, playerSpot.side
		end
		return nil
	end
	local actor = actors[speaker]
	if not actor then
		return nil
	end
	local head = actor.model:FindFirstChild("Head") :: BasePart?
	return head, actor.spot.cf, actor.spot.side
end

function Stage.has(speaker: string): boolean
	return speaker == "player" or actors[speaker] ~= nil
end

-- A small gesture for emphasis (used on objections).
function Stage.gesture(speaker: string)
	local model: Model? = nil
	if speaker == "player" then
		model = player.Character
	elseif actors[speaker] then
		model = actors[speaker].model
	end
	if not model then
		return
	end
	local track = loadTrack(model, POINT_ANIMATION, false)
	if track then
		track.Priority = Enum.AnimationPriority.Action
		track:Play(0.1)
	end
end

function Stage.displayName(speaker: string): (string, string)
	if speaker == "player" then
		return player.DisplayName, "Associate, Valence Legal"
	end
	local character = Characters[speaker]
	if character then
		return character.name, character.role
	end
	return speaker, ""
end

----------------------------------------------------------------- other players
local others: { [Player]: { character: Model?, tag: BillboardGui?, shown: boolean } } = {}

local function setCharacterVisible(character: Model, visible: boolean)
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = if visible then 0 else 1
		elseif d:IsA("Decal") then
			d.Transparency = if visible then 0 else 1
		end
	end
end

local function makeTag(other: Player, character: Model): BillboardGui?
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then
		return nil
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "CareerTag"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(200, 44)
	gui.StudsOffset = Vector3.new(0, 2.4, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, 0, 0, 24)
	name.Text = other.DisplayName
	name.TextColor3 = Color3.fromRGB(246, 241, 231)
	name.TextStrokeTransparency = 0.5
	name.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
	name.TextSize = 18
	name.Parent = gui
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(0, 24)
	title.Size = UDim2.new(1, 0, 0, 18)
	title.Text = tostring(other:GetAttribute("Title") or "Junior Associate")
	title.TextColor3 = Color3.fromRGB(205, 172, 112)
	title.TextStrokeTransparency = 0.5
	title.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold)
	title.TextSize = 13
	title.Parent = gui
	other:GetAttributeChangedSignal("Title"):Connect(function()
		title.Text = tostring(other:GetAttribute("Title") or "")
	end)
	gui.Parent = head
	return gui
end

local function trackOther(other: Player, character: Model)
	local entry = others[other] or { shown = false }
	entry.character = character
	entry.shown = false
	others[other] = entry
	setCharacterVisible(character, false)
	character.DescendantAdded:Connect(function(d)
		if not entry.shown then
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = 1
			elseif d:IsA("Decal") then
				d.Transparency = 1
			end
		end
	end)
	if entry.tag then
		entry.tag:Destroy()
		entry.tag = nil
	end
end

-- Show the nearest N other players (lobby) or none (case). Runs twice a second.
local function updateVisibility()
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local ranked = {}
	for other, entry in others do
		local root = entry.character and entry.character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if entry.character and entry.character.Parent and root then
			local distance = if myRoot then (root.Position - myRoot.Position).Magnitude else math.huge
			table.insert(ranked, { other = other, entry = entry, distance = distance })
		end
	end
	table.sort(ranked, function(a, b)
		return a.distance < b.distance
	end)
	for index, item in ranked do
		local show = lobbyMode and index <= Config.Lobby.visiblePlayers
		if show ~= item.entry.shown then
			item.entry.shown = show
			setCharacterVisible(item.entry.character :: Model, show)
			if show and not item.entry.tag then
				item.entry.tag = makeTag(item.other, item.entry.character :: Model)
			elseif not show and item.entry.tag then
				item.entry.tag:Destroy()
				item.entry.tag = nil
			end
		end
	end
end

----------------------------------------------------------------- modes
-- Lobby: walk around the office and see other associates. Case: private, parked, hidden.
function Stage.setLobbyMode(enabled: boolean)
	lobbyMode = enabled
	setWalking(enabled)
	updateVisibility()
end

function Stage.isLobby(): boolean
	return lobbyMode
end

function Stage.init()
	local function watch(other: Player)
		if other == player then
			return
		end
		if other.Character then
			trackOther(other, other.Character)
		end
		other.CharacterAdded:Connect(function(character)
			trackOther(other, character)
		end)
	end
	for _, other in Players:GetPlayers() do
		watch(other)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(other)
		local entry = others[other]
		if entry and entry.tag then
			entry.tag:Destroy()
		end
		others[other] = nil
	end)

	-- Our own avatar: parked unless the lobby says otherwise.
	local function lockSelf(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		setWalking(lobbyMode)
	end
	if player.Character then
		task.spawn(lockSelf, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		lockSelf(character)
		if playerSpot and not lobbyMode then
			task.wait(0.2)
			for name, spot in StageLayout.Spots do
				if spot == playerSpot then
					Stage.placePlayer(name)
					break
				end
			end
		end
	end)

	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator >= 0.5 then
			accumulator = 0
			updateVisibility()
		end
	end)
end

return Stage
