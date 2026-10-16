--[[
	Stage — the player's private set. Places local copies of the cast on their
	marks, positions the player's own avatar, and hides other players so a
	shared server still feels like a personal story.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StageLayout = require(Shared.StageLayout)
local Characters = require(Shared.Characters)

local Stage = {}

local player = Players.LocalPlayer
local IDLE_ANIMATION = "rbxassetid://507766388" -- Roblox's default R15 idle
local POINT_ANIMATION = "rbxassetid://507770453" -- Roblox's default R15 "point" emote

local folder: Folder? = nil
local actors: { [string]: { model: Model, spot: StageLayout.Spot, tracks: { [string]: AnimationTrack } } } =
	{}
local playerSpot: StageLayout.Spot? = nil

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

function Stage.character(): Model?
	return player.Character
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

-- Keep other players invisible locally (single-player story in a shared server).
local function hideCharacter(character: Model)
	local function hide(d: Instance)
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 1
			d.Transparency = 1
		elseif d:IsA("Decal") then
			d.Transparency = 1
		end
	end
	for _, d in character:GetDescendants() do
		hide(d)
	end
	character.DescendantAdded:Connect(hide)
end

function Stage.init()
	local function watch(other: Player)
		if other == player then
			return
		end
		if other.Character then
			hideCharacter(other.Character)
		end
		other.CharacterAdded:Connect(hideCharacter)
	end
	for _, other in Players:GetPlayers() do
		watch(other)
	end
	Players.PlayerAdded:Connect(watch)

	-- Our own avatar never walks or jumps: everything is tap-driven.
	local function lockSelf(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
	if player.Character then
		task.spawn(lockSelf, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		lockSelf(character)
		if playerSpot then
			task.wait(0.2)
			for name, spot in StageLayout.Spots do
				if spot == playerSpot then
					Stage.placePlayer(name)
					break
				end
			end
		end
	end)
end

return Stage
