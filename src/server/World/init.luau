--[[
	World — builds the whole environment at server start.
	Everything is generated from code (no external asset packs) and kept lean
	for phones and iPads: ~1,000 anchored parts, a dozen non-shadow lights.
]]

local Lighting = game:GetService("Lighting")

local Palette = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Palette)
local Builder = require(script.Builder)
local Office = require(script.Office)
local Courtroom = require(script.Courtroom)

local World = {}

-- Bump when the builders change so stale baked worlds are rebuilt at runtime.
World.VERSION = 1

local function skyline(root: Instance)
	-- Northbridge at golden hour, seen through the office's back windows.
	local folder = Builder.folder(root, "Skyline")
	local towers = {
		{ -110, 60, 24, 130 },
		{ -78, 92, 18, 170 },
		{ -50, 70, 26, 110 },
		{ -20, 110, 20, 190 },
		{ 8, 80, 30, 140 },
		{ 40, 120, 22, 210 },
		{ 70, 75, 26, 120 },
		{ 100, 95, 20, 165 },
		{ -95, 150, 30, 150 },
		{ -35, 160, 34, 200 },
		{ 25, 170, 28, 175 },
		{ 85, 155, 30, 140 },
	}
	for i, t in towers do
		local x, z, w, h = t[1], -t[2], t[3], t[4]
		local tone = if i % 3 == 0 then Palette.Stone elseif i % 3 == 1 then Palette.NavySoft else Palette.Navy
		local bottom = -120
		Builder.trim(
			folder,
			Vector3.new(w, h, w),
			CFrame.new(x, bottom + h / 2, z),
			tone,
			Enum.Material.Concrete
		)
		-- a couple of lit window bands per tower (cheap neon strips)
		for band = 1, 2 do
			Builder.glow(
				folder,
				Vector3.new(w * 0.8, 0.8, 0.2),
				CFrame.new(x, bottom + h - band * 9, z + w / 2 + 0.11),
				Palette.WarmLight
			)
		end
		Builder.trim(
			folder,
			Vector3.new(w + 1, 2, w + 1),
			CFrame.new(x, bottom + h + 1, z),
			Palette.BrassDark,
			Enum.Material.Metal
		)
	end
end

local function atmosphere()
	local function ensure(className: string, name: string): Instance
		local existing = Lighting:FindFirstChild(name)
		if existing then
			return existing
		end
		local inst = Instance.new(className)
		inst.Name = name
		inst.Parent = Lighting
		return inst
	end

	local atmo = ensure("Atmosphere", "FirstChairAtmosphere") :: Atmosphere
	atmo.Density = 0.32
	atmo.Offset = 0.15
	atmo.Color = Color3.fromRGB(214, 190, 160)
	atmo.Decay = Color3.fromRGB(120, 100, 90)
	atmo.Glare = 0.2
	atmo.Haze = 1.4

	local grade = ensure("ColorCorrectionEffect", "FirstChairGrade") :: ColorCorrectionEffect
	grade.Brightness = 0.02
	grade.Contrast = 0.08
	grade.Saturation = -0.06
	grade.TintColor = Color3.fromRGB(255, 246, 234)

	local bloom = ensure("BloomEffect", "FirstChairBloom") :: BloomEffect
	bloom.Intensity = 0.35
	bloom.Size = 22
	bloom.Threshold = 1.6

	-- Runtime-safe lighting values (Technology is set in default.project.json).
	Lighting.Ambient = Color3.fromRGB(92, 80, 70)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 128, 118)
	Lighting.Brightness = 2.2
	Lighting.ClockTime = 16.6
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.4
end

function World.build()
	local existing = workspace:FindFirstChild("FirstChairWorld")
	if existing and existing:GetAttribute("Baked") == World.VERSION then
		-- Already baked into the place file by scripts/bake.luau: just set the mood.
		atmosphere()
		print("[FirstChair] Using baked world")
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "FirstChairWorld"

	Builder.partCount = 0
	Office.build(root)
	Courtroom.build(root)
	skyline(root)
	atmosphere()

	root.Parent = workspace
	print(("[FirstChair] World built: %d parts"):format(Builder.partCount))
	return root
end

return World
