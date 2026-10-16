--[[
	Builder — small helpers for building tidy, efficient architecture from parts.

	Rules that keep the world cheap on mobile:
	  * everything is Anchored
	  * decorative parts don't collide, touch or cast shadows
	  * only a handful of real lights, all without shadows
]]

local Palette = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Palette)

local Builder = {}

Builder.Palette = Palette
Builder.partCount = 0

export type Opts = {
	material: Enum.Material?,
	collide: boolean?,
	shadow: boolean?,
	transparency: number?,
	reflectance: number?,
	shape: Enum.PartType?,
	name: string?,
}

local M = Enum.Material

function Builder.part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, opts: Opts?): Part
	local o: Opts = opts or {}
	local p = Instance.new("Part")
	p.Name = o.name or "Part"
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = o.material or M.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = o.collide == true
	p.CanTouch = false
	p.CanQuery = o.collide == true
	p.CastShadow = o.shadow == true
	p.Transparency = o.transparency or 0
	p.Reflectance = o.reflectance or 0
	if o.shape then
		p.Shape = o.shape
	end
	p.Parent = parent
	Builder.partCount += 1
	return p
end

-- Solid architecture (floors, walls): collides and casts shadows.
function Builder.solid(
	parent: Instance,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	return Builder.part(parent, size, cf, color, { material = material, collide = true, shadow = true })
end

-- Decorative detail: no collision, no shadow.
function Builder.trim(
	parent: Instance,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	return Builder.part(parent, size, cf, color, { material = material })
end

function Builder.cylinder(
	parent: Instance,
	length: number,
	diameter: number,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	-- Roblox cylinders run along the part's X axis; callers pass cf already oriented.
	return Builder.part(parent, Vector3.new(length, diameter, diameter), cf, color, {
		material = material,
		shape = Enum.PartType.Cylinder,
	})
end

-- Vertical cylinder standing on `base` (a floor-level position).
function Builder.post(
	parent: Instance,
	height: number,
	diameter: number,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	return Builder.cylinder(
		parent,
		height,
		diameter,
		cf * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		material
	)
end

function Builder.ball(
	parent: Instance,
	diameter: number,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	return Builder.part(parent, Vector3.new(diameter, diameter, diameter), cf, color, {
		material = material,
		shape = Enum.PartType.Ball,
	})
end

function Builder.glass(parent: Instance, size: Vector3, cf: CFrame): Part
	return Builder.part(parent, size, cf, Palette.Glass, {
		material = M.Glass,
		transparency = 0.72,
		reflectance = 0.08,
		collide = true,
	})
end

-- A glowing strip (fake light fixture — costs nothing).
function Builder.glow(parent: Instance, size: Vector3, cf: CFrame, color: Color3?): Part
	return Builder.part(parent, size, cf, color or Palette.WarmLight, { material = M.Neon })
end

function Builder.light(
	parent: BasePart,
	kind: "Point" | "Surface" | "Spot",
	brightness: number,
	range: number,
	color: Color3?,
	face: Enum.NormalId?
)
	local light: Light
	if kind == "Surface" then
		local s = Instance.new("SurfaceLight")
		s.Face = face or Enum.NormalId.Bottom
		s.Angle = 110
		light = s
	elseif kind == "Spot" then
		local s = Instance.new("SpotLight")
		s.Face = face or Enum.NormalId.Bottom
		s.Angle = 70
		light = s
	else
		light = Instance.new("PointLight")
	end
	light.Brightness = brightness
	light.Color = color or Palette.WarmLight
	light.Shadows = false;
	(light :: any).Range = range
	light.Parent = parent
	return light
end

-- Text painted onto a face of a part (signage, plaques, case boards).
function Builder.label(
	parent: BasePart,
	face: Enum.NormalId,
	text: string,
	opts: {
		font: Font?,
		color: Color3?,
		ppu: number?,
		size: number?,
		bold: boolean?,
		align: Enum.TextXAlignment?,
	}?
): SurfaceGui
	local o = opts or {}
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = o.ppu or 40
	gui.LightInfluence = 0.6
	gui.MaxDistance = 140
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = o.color or Palette.Brass
	label.FontFace = o.font
		or Font.new(
			"rbxasset://fonts/families/Merriweather.json",
			if o.bold then Enum.FontWeight.Bold else Enum.FontWeight.Regular
		)
	label.TextScaled = o.size == nil
	if o.size then
		label.TextSize = o.size
	end
	label.TextWrapped = true
	label.TextXAlignment = o.align or Enum.TextXAlignment.Center
	label.Parent = gui
	return gui
end

function Builder.folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

--[[ Reusable furniture ]]

-- A simple, elegant chair. `cf` is floor-level, facing the seat's front.
function Builder.chair(parent: Instance, cf: CFrame, upholstery: Color3?, wood: Color3?)
	local w = wood or Palette.Espresso
	local u = upholstery or Palette.Leather
	Builder.trim(parent, Vector3.new(2, 0.5, 2), cf * CFrame.new(0, 1.7, 0), u, M.Leather)
	Builder.trim(parent, Vector3.new(2, 2.2, 0.35), cf * CFrame.new(0, 3.0, 0.85), u, M.Leather)
	for _, x in { -0.8, 0.8 } do
		for _, z in { -0.8, 0.8 } do
			Builder.trim(parent, Vector3.new(0.22, 1.5, 0.22), cf * CFrame.new(x, 0.75, z), w, M.Wood)
		end
	end
end

-- Rectangular table with a contrasting top and inset legs.
function Builder.table(
	parent: Instance,
	cf: CFrame,
	size: Vector3,
	top: Color3?,
	legs: Color3?,
	topMaterial: Enum.Material?
)
	local h = size.Y
	Builder.solid(
		parent,
		Vector3.new(size.X, 0.35, size.Z),
		cf * CFrame.new(0, h - 0.175, 0),
		top or Palette.Walnut,
		topMaterial or M.Wood
	)
	Builder.trim(
		parent,
		Vector3.new(size.X - 0.6, 0.45, size.Z - 0.6),
		cf * CFrame.new(0, h - 0.55, 0),
		legs or Palette.Espresso,
		M.Wood
	)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			Builder.trim(
				parent,
				Vector3.new(0.4, h - 0.35, 0.4),
				cf * CFrame.new(x * (size.X / 2 - 0.6), (h - 0.35) / 2, z * (size.Z / 2 - 0.6)),
				legs or Palette.Espresso,
				M.Wood
			)
		end
	end
end

-- Potted plant: brass-rimmed planter with a layered canopy.
function Builder.plant(parent: Instance, cf: CFrame, scale: number?)
	local s = scale or 1
	Builder.post(parent, 2.2 * s, 2.2 * s, cf, Palette.Espresso, M.Slate)
	Builder.post(parent, 0.15, 2.35 * s, cf * CFrame.new(0, 2.2 * s, 0), Palette.Brass, M.Metal)
	Builder.ball(parent, 2.8 * s, cf * CFrame.new(0, 3.6 * s, 0), Palette.Leaf, M.Grass)
	Builder.ball(parent, 2.1 * s, cf * CFrame.new(0.6 * s, 4.7 * s, 0.3 * s), Palette.Sage, M.Grass)
	Builder.ball(parent, 1.7 * s, cf * CFrame.new(-0.6 * s, 4.9 * s, -0.4 * s), Palette.Leaf, M.Grass)
end

-- Brass wall sconce with a soft glow and a cheap point light.
function Builder.sconce(parent: Instance, cf: CFrame, withLight: boolean?)
	Builder.trim(parent, Vector3.new(0.6, 1.2, 0.2), cf, Palette.Brass, M.Metal)
	local shade = Builder.trim(
		parent,
		Vector3.new(0.9, 0.8, 0.7),
		cf * CFrame.new(0, 0.6, -0.4),
		Palette.Cream,
		M.Fabric
	)
	if withLight then
		Builder.light(shade, "Point", 0.8, 12, Palette.WarmLight)
	end
end

return Builder
