--[[
	Cast — builds one template model per character into ReplicatedStorage.
	Clients clone these locally, so every player gets a private "stage" and
	two players in different cases never see each other's actors.

	Characters are standard R15 rigs (from a HumanoidDescription) with body colours
	as clothing, plus a few welded parts for hair, collar and tie. No asset IDs.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Characters = require(ReplicatedStorage:WaitForChild("Shared").Characters)

local Cast = {}

Cast.FOLDER = "FirstChairCast"

local function weld(part: BasePart, to: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = part
	w.Parent = part
end

local function accessoryPart(
	model: Model,
	attachTo: BasePart,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	mesh: boolean?
)
	local p = Instance.new("Part")
	p.Name = "Detail"
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = attachTo.CFrame * offset
	if mesh then
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
	end
	p.Parent = model
	weld(p, attachTo)
	return p
end

local function addHair(model: Model, head: BasePart, style: string, color: Color3)
	if style == "none" then
		return
	end
	local s = head.Size
	-- head front is -Z
	if style == "crop" then
		accessoryPart(
			model,
			head,
			Vector3.new(s.X * 1.06, s.Y * 0.42, s.Z * 1.08),
			CFrame.new(0, s.Y * 0.34, 0.03),
			color,
			true
		)
	elseif style == "short" then
		accessoryPart(
			model,
			head,
			Vector3.new(s.X * 1.1, s.Y * 0.55, s.Z * 1.12),
			CFrame.new(0, s.Y * 0.3, 0.05),
			color,
			true
		)
		accessoryPart(
			model,
			head,
			Vector3.new(s.X * 1.04, s.Y * 0.5, s.Z * 0.4),
			CFrame.new(0, s.Y * 0.05, s.Z * 0.38),
			color,
			true
		)
	elseif style == "slick" then
		accessoryPart(
			model,
			head,
			Vector3.new(s.X * 1.08, s.Y * 0.5, s.Z * 1.15),
			CFrame.new(0, s.Y * 0.33, 0.1) * CFrame.Angles(math.rad(-6), 0, 0),
			color,
			true
		)
	elseif style == "bob" then
		accessoryPart(
			model,
			head,
			Vector3.new(s.X * 1.14, s.Y * 0.6, s.Z * 1.14),
			CFrame.new(0, s.Y * 0.28, 0.04),
			color,
			true
		)
		accessoryPart(
			model,
			head,
			Vector3.new(s.X * 1.2, s.Y * 0.85, s.Z * 0.75),
			CFrame.new(0, -s.Y * 0.05, s.Z * 0.22),
			color,
			true
		)
	elseif style == "long" then
		accessoryPart(
			model,
			head,
			Vector3.new(s.X * 1.14, s.Y * 0.6, s.Z * 1.14),
			CFrame.new(0, s.Y * 0.28, 0.04),
			color,
			true
		)
		accessoryPart(
			model,
			head,
			Vector3.new(s.X * 1.12, s.Y * 1.5, s.Z * 0.5),
			CFrame.new(0, -s.Y * 0.3, s.Z * 0.42),
			color,
			true
		)
	elseif style == "bun" then
		accessoryPart(
			model,
			head,
			Vector3.new(s.X * 1.1, s.Y * 0.55, s.Z * 1.12),
			CFrame.new(0, s.Y * 0.3, 0.04),
			color,
			true
		)
		accessoryPart(
			model,
			head,
			Vector3.new(s.X * 0.55, s.X * 0.55, s.X * 0.55),
			CFrame.new(0, s.Y * 0.42, s.Z * 0.55),
			color,
			true
		)
	end
end

local function dress(model: Model, look)
	local head = model:FindFirstChild("Head") :: BasePart?
	local torso: BasePart? = (model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")) :: any
	if head then
		addHair(model, head, look.hairStyle, look.hair)
		if not head:FindFirstChildOfClass("Decal") then
			local face = Instance.new("Decal")
			face.Name = "face"
			face.Texture = "rbxasset://textures/face.png"
			face.Face = Enum.NormalId.Front
			face.Parent = head
		end
	end
	if torso then
		local t = torso.Size
		if look.collar then
			accessoryPart(
				model,
				torso,
				Vector3.new(t.X * 0.34, t.Y * 0.42, 0.08),
				CFrame.new(0, t.Y * 0.28, -t.Z / 2 - 0.02),
				look.collar
			)
		end
		if look.tie then
			accessoryPart(
				model,
				torso,
				Vector3.new(t.X * 0.1, t.Y * 0.62, 0.06),
				CFrame.new(0, t.Y * 0.1, -t.Z / 2 - 0.07),
				look.tie
			)
		end
	end
end

local function fromDescription(look): Model?
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = look.skin
	desc.TorsoColor = look.top
	desc.LeftArmColor = look.top
	desc.RightArmColor = look.top
	desc.LeftLegColor = look.bottom
	desc.RightLegColor = look.bottom
	desc.HeightScale = look.scale or 1
	local ok, result = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if ok and result then
		return result
	end
	warn("[FirstChair] Could not build R15 rig, using a simple figure:", result)
	return nil
end

-- Fallback figure if rig creation is unavailable: still readable on camera.
local function simpleFigure(look): Model
	local model = Instance.new("Model")
	local function block(name: string, size: Vector3, cf: CFrame, color: Color3): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Anchored = true
		p.CanCollide = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local root = block("HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0), look.top)
	root.Transparency = 1
	block("LowerBody", Vector3.new(1.8, 2, 0.9), CFrame.new(0, 1, 0), look.bottom)
	block("UpperTorso", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0), look.top)
	block("LeftArm", Vector3.new(0.8, 2, 0.8), CFrame.new(-1.4, 3, 0), look.top)
	block("RightArm", Vector3.new(0.8, 2, 0.8), CFrame.new(1.4, 3, 0), look.top)
	local head = block("Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 4.6, 0), look.skin)
	head.Shape = Enum.PartType.Ball
	model.PrimaryPart = root
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part ~= root then
			weld(part, root)
			part.Anchored = false
		end
	end
	return model
end

function Cast.build()
	local folder = ReplicatedStorage:FindFirstChild(Cast.FOLDER)
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = Cast.FOLDER

	for id, character in Characters do
		local model = fromDescription(character.look) or simpleFigure(character.look)
		model.Name = id
		dress(model, character.look)
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			humanoid.BreakJointsOnDeath = false
			humanoid.RequiresNeck = false
		end
		-- scripts inside generated rigs (e.g. Animate) aren't needed for actors
		for _, d in model:GetDescendants() do
			if d:IsA("BaseScript") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.CanCollide = false
				d.CanTouch = false
				d.CanQuery = false
			end
		end
		model:SetAttribute("DisplayName", character.name)
		model.Parent = folder
	end

	folder.Parent = ReplicatedStorage
	return folder
end

return Cast
