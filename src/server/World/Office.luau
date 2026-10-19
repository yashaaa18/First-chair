--[[
	Office — the Valence Legal lobby: reception, lounge with the case board,
	and glass-walled Conference Room B. Interior: x -32..32, z -22..22, h 16.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local StageLayout = require(Shared.StageLayout)
local CaseCatalog = require(Shared.CaseCatalog)
local B = require(script.Parent.Builder)

local C = B.Palette
local M = Enum.Material

local Office = {}

local W, D, H = 64, 44, 16 -- interior width (x), depth (z), height

function Office.build(root: Instance)
	local O = StageLayout.Origins.office
	local function at(x: number, y: number, z: number): CFrame
		return O * CFrame.new(x, y, z)
	end
	local function rot(x: number, y: number, z: number, yaw: number): CFrame
		return O * CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0)
	end

	local model = B.folder(root, "Office")
	local shell = B.folder(model, "Shell")
	local decor = B.folder(model, "Decor")

	----------------------------------------------------------------- floor
	B.solid(shell, Vector3.new(W + 2, 1, D + 2), at(0, -0.5, 0), C.Stone, M.Marble)
	-- walnut inlay frame around the central lobby
	for _, z in { -6, 18 } do
		B.trim(decor, Vector3.new(22, 0.06, 0.5), at(0, 0.03, z), C.Walnut, M.Wood)
	end
	for _, x in { -11, 11 } do
		B.trim(decor, Vector3.new(0.5, 0.06, 24), at(x, 0.03, 6), C.Walnut, M.Wood)
	end
	-- navy runner from the doors to reception
	B.trim(decor, Vector3.new(6, 0.08, 26), at(0, 0.04, 8), C.Navy, M.Fabric)
	B.trim(decor, Vector3.new(6.6, 0.06, 26.6), at(0, 0.03, 8), C.Brass, M.Metal)

	----------------------------------------------------------------- ceiling
	B.solid(shell, Vector3.new(W + 2, 1, D + 2), at(0, H + 0.5, 0), C.Plaster, M.Plaster)
	-- central coffer with warm cove lighting
	local cofferY = H - 0.6
	for _, z in { -6, 18 } do
		B.trim(decor, Vector3.new(24, 1.2, 1), at(0, cofferY, z), C.Walnut, M.Wood)
		B.glow(decor, Vector3.new(22, 0.15, 0.3), at(0, cofferY - 0.3, z + (z < 0 and 0.7 or -0.7)))
	end
	for _, x in { -12, 12 } do
		B.trim(decor, Vector3.new(1, 1.2, 25), at(x, cofferY, 6), C.Walnut, M.Wood)
		B.glow(decor, Vector3.new(0.3, 0.15, 22), at(x + (x < 0 and 0.7 or -0.7), cofferY - 0.3, 6))
	end

	----------------------------------------------------------------- walls
	local function wainscot(size: Vector3, cf: CFrame)
		B.trim(decor, size, cf, C.Walnut, M.Wood)
		B.trim(
			decor,
			Vector3.new(size.X + 0.1, 0.25, size.Z + 0.1),
			cf * CFrame.new(0, size.Y / 2 + 0.1, 0),
			C.Brass,
			M.Metal
		)
	end

	-- Left wall (x = -32) and right wall (x = 32)
	for _, side in { -1, 1 } do
		local x = side * (W / 2 + 0.5)
		B.solid(shell, Vector3.new(1, H, D + 2), at(x, H / 2, 0), C.Plaster, M.Plaster)
		wainscot(Vector3.new(0.3, 4, D), at(x - side * 0.65, 2, 0))
		B.trim(decor, Vector3.new(0.6, 0.8, D), at(x - side * 0.8, H - 0.4, 0), C.Espresso, M.Wood) -- crown
	end

	-- Front wall (z = 22) with glass entrance doors in the middle
	local frontZ = D / 2 + 0.5
	for _, side in { -1, 1 } do
		local segW = W / 2 - 5
		local cx = side * (5 + segW / 2)
		B.solid(shell, Vector3.new(segW, H, 1), at(cx, H / 2, frontZ), C.Plaster, M.Plaster)
		wainscot(Vector3.new(segW, 4, 0.3), at(cx, 2, frontZ - 0.65))
		B.trim(decor, Vector3.new(segW, 0.8, 0.6), at(cx, H - 0.4, frontZ - 0.8), C.Espresso, M.Wood)
	end
	B.solid(shell, Vector3.new(10, H - 11, 1), at(0, 11 + (H - 11) / 2, frontZ), C.Plaster, M.Plaster)
	B.trim(decor, Vector3.new(10.4, 0.5, 1.2), at(0, 11, frontZ), C.Brass, M.Metal)
	for _, side in { -1, 1 } do
		B.glass(decor, Vector3.new(4.9, 11, 0.25), at(side * 2.5, 5.5, frontZ))
		B.trim(decor, Vector3.new(0.3, 11, 0.5), at(side * 5, 5.5, frontZ), C.Brass, M.Metal)
		B.trim(decor, Vector3.new(0.15, 3.5, 0.15), at(side * 0.6, 4.5, frontZ - 0.35), C.Brass, M.Metal)
	end
	B.trim(decor, Vector3.new(0.3, 11, 0.5), at(0, 5.5, frontZ), C.Brass, M.Metal)

	-- Back wall (z = -22): windows left and right, feature wall in the middle
	local backZ = -D / 2 - 0.5
	B.solid(shell, Vector3.new(28, H, 1), at(0, H / 2, backZ), C.Plaster, M.Plaster)
	for _, side in { -1, 1 } do
		local cx = side * 23
		-- sill, header and end pieces around a big window (x 14..30 / -30..-14)
		B.solid(shell, Vector3.new(18, 3, 1), at(cx, 1.5, backZ), C.Plaster, M.Plaster)
		B.solid(shell, Vector3.new(18, 3, 1), at(cx, H - 1.5, backZ), C.Plaster, M.Plaster)
		B.solid(shell, Vector3.new(2, H, 1), at(side * 31, H / 2, backZ), C.Plaster, M.Plaster)
		local gx = side * 22 -- glass spans x 14..30 (or -30..-14)
		B.glass(shell, Vector3.new(16, H - 6, 0.3), at(gx, H / 2, backZ))
		B.trim(decor, Vector3.new(16.4, 0.4, 1.4), at(gx, 3.1, backZ + 0.2), C.Walnut, M.Wood) -- sill
		for i = 0, 4 do
			B.trim(
				decor,
				Vector3.new(0.25, H - 6, 0.4),
				at(gx - 8 + i * 4, H / 2, backZ + 0.1),
				C.Brass,
				M.Metal
			)
		end
		B.trim(decor, Vector3.new(16, 0.25, 0.4), at(gx, 9.5, backZ + 0.1), C.Brass, M.Metal)
	end

	----------------------------------------------------------------- reception
	local rec = B.folder(model, "Reception")
	-- navy feature wall with walnut slats either side
	B.trim(rec, Vector3.new(22, 12, 0.6), at(0, 8, backZ + 0.8), C.Navy, M.SmoothPlastic)
	B.trim(rec, Vector3.new(22.6, 0.3, 0.8), at(0, 14.15, backZ + 0.9), C.Brass, M.Metal)
	B.trim(rec, Vector3.new(22.6, 0.3, 0.8), at(0, 1.85, backZ + 0.9), C.Brass, M.Metal)
	for side = -1, 1, 2 do
		for i = 0, 2 do
			B.trim(
				rec,
				Vector3.new(0.5, H - 0.5, 0.6),
				at(side * (11.8 + i * 0.75), H / 2, backZ + 0.8),
				C.Walnut,
				M.Wood
			)
		end
	end
	-- monogram: a brass "V" over the name
	local vTop = 11.4
	for _, side in { -1, 1 } do
		B.trim(
			rec,
			Vector3.new(0.35, 3.2, 0.2),
			at(side * 0.55, vTop, backZ + 1.2) * CFrame.Angles(0, 0, math.rad(side * 18)),
			C.Brass,
			M.Metal
		)
	end
	local sign =
		B.part(rec, Vector3.new(16, 2.2, 0.1), at(0, 8.3, backZ + 1.15), C.Navy, { transparency = 1 })
	B.label(sign, Enum.NormalId.Back, "VALENCE  LEGAL", { bold = true, color = C.Gold })
	local tagline =
		B.part(rec, Vector3.new(12, 0.8, 0.1), at(0, 6.7, backZ + 1.15), C.Navy, { transparency = 1 })
	B.label(tagline, Enum.NormalId.Back, "ATTORNEYS AT LAW  ·  NORTHBRIDGE  ·  EST. 1984", {
		color = C.Cream,
		font = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium),
	})

	-- counter: walnut body, vertical fluting, ivory marble top, brass kick
	local counterZ = -10
	B.solid(rec, Vector3.new(16, 3.6, 3), at(0, 1.8, counterZ), C.Walnut, M.Wood)
	for i = -7, 7, 2 do
		B.trim(rec, Vector3.new(0.35, 3.0, 0.15), at(i, 1.9, counterZ + 1.55), C.Espresso, M.Wood)
	end
	B.trim(rec, Vector3.new(16.2, 0.3, 3.2), at(0, 0.15, counterZ), C.Brass, M.Metal)
	B.trim(rec, Vector3.new(16.8, 0.3, 3.6), at(0, 3.75, counterZ), C.Ivory, M.Marble)
	for _, x in { -8.2, 8.2 } do
		B.trim(rec, Vector3.new(0.4, 3.6, 3.2), at(x, 1.8, counterZ), C.Espresso, M.Wood)
	end
	-- counter dressing
	B.trim(
		rec,
		Vector3.new(2.2, 1.4, 0.15),
		at(3.2, 4.8, counterZ - 0.6) * CFrame.Angles(math.rad(-8), 0, 0),
		C.Charcoal,
		M.SmoothPlastic
	)
	B.trim(rec, Vector3.new(0.3, 0.6, 0.3), at(3.2, 4.2, counterZ - 0.45), C.Charcoal, M.SmoothPlastic)
	B.post(rec, 0.9, 0.7, at(-5, 3.9, counterZ + 0.4), C.Ivory, M.Glass)
	B.ball(rec, 1.2, at(-5, 5.2, counterZ + 0.4), C.Burgundy, M.Fabric)
	B.ball(rec, 0.8, at(-4.6, 5.6, counterZ + 0.6), C.Cream, M.Fabric)
	B.trim(rec, Vector3.new(1.6, 0.2, 1.1), at(-1, 4.0, counterZ + 0.5), C.Navy, M.Leather) -- guest book
	B.trim(rec, Vector3.new(0.05, 0.05, 0.9), at(-0.6, 4.13, counterZ + 0.5), C.Brass, M.Metal)

	-- three brass pendants above the counter
	for _, x in { -5, 0, 5 } do
		B.trim(rec, Vector3.new(0.08, 4, 0.08), at(x, H - 2, counterZ), C.Brass, M.Metal)
		local shade = B.post(rec, 0.9, 1.6, at(x, H - 5, counterZ), C.Brass, M.Metal)
		B.glow(rec, Vector3.new(1.2, 0.1, 1.2), at(x, H - 5.05, counterZ))
		if x == 0 then
			B.light(shade, "Point", 1.4, 22, C.WarmLight)
		end
	end
	B.chair(rec, rot(-1.5, 0, -14.6, 180), C.Navy)

	----------------------------------------------------------------- lounge + case board (left)
	local lounge = B.folder(model, "Lounge")
	B.trim(lounge, Vector3.new(13, 0.08, 15), at(-23, 0.04, 4), C.Navy, M.Fabric)
	B.trim(lounge, Vector3.new(13.6, 0.06, 15.6), at(-23, 0.03, 4), C.Cream, M.Fabric)

	-- sofa against the left wall, facing +x
	local sofa = rot(-28.6, 0, 4, -90)
	B.trim(lounge, Vector3.new(9, 1.6, 3.2), sofa * CFrame.new(0, 0.8, 0), C.NavySoft, M.Fabric)
	B.trim(lounge, Vector3.new(9, 2.6, 0.8), sofa * CFrame.new(0, 2.3, 1.2), C.NavySoft, M.Fabric)
	for _, sx in { -4.8, 4.8 } do
		B.trim(lounge, Vector3.new(0.7, 2.4, 3.4), sofa * CFrame.new(sx, 1.2, 0), C.NavySoft, M.Fabric)
	end
	for _, sx in { -2.2, 2.2 } do
		B.trim(lounge, Vector3.new(4.2, 0.5, 2.6), sofa * CFrame.new(sx, 1.85, -0.1), C.Navy, M.Fabric)
	end
	B.trim(
		lounge,
		Vector3.new(1.3, 1.1, 0.4),
		sofa * CFrame.new(-3, 2.6, 0.7) * CFrame.Angles(math.rad(-15), 0, math.rad(8)),
		C.Brass,
		M.Fabric
	)
	B.trim(
		lounge,
		Vector3.new(1.3, 1.1, 0.4),
		sofa * CFrame.new(3, 2.6, 0.7) * CFrame.Angles(math.rad(-15), 0, math.rad(-8)),
		C.Cream,
		M.Fabric
	)

	-- armchairs facing the sofa
	for _, z in { 0.5, 7.5 } do
		local chair = rot(-17.5, 0, z, 90)
		B.trim(lounge, Vector3.new(3, 1.5, 3), chair * CFrame.new(0, 0.75, 0), C.Leather, M.Leather)
		B.trim(lounge, Vector3.new(3, 2.4, 0.6), chair * CFrame.new(0, 2.2, 1.2), C.Leather, M.Leather)
		for _, ax in { -1.5, 1.5 } do
			B.trim(lounge, Vector3.new(0.5, 2.1, 3), chair * CFrame.new(ax, 1.05, 0), C.Leather, M.Leather)
		end
	end

	-- coffee table: walnut base, marble top, a stack of books
	B.trim(lounge, Vector3.new(3, 1.2, 5), at(-23, 0.6, 4), C.Espresso, M.Wood)
	B.trim(lounge, Vector3.new(3.6, 0.25, 5.8), at(-23, 1.33, 4), C.Ivory, M.Marble)
	B.trim(lounge, Vector3.new(1.4, 0.3, 1.9), at(-23, 1.6, 2.6), C.Navy, M.Fabric)
	B.trim(
		lounge,
		Vector3.new(1.2, 0.25, 1.7),
		at(-23, 1.88, 2.6) * CFrame.Angles(0, math.rad(12), 0),
		C.Burgundy,
		M.Fabric
	)
	B.post(lounge, 0.5, 0.6, at(-23, 1.45, 5.6), C.Brass, M.Metal)

	-- floor lamp
	B.post(lounge, 0.2, 1.4, at(-29.5, 0, -4), C.Brass, M.Metal)
	B.post(lounge, 7, 0.15, at(-29.5, 0, -4), C.Brass, M.Metal)
	local lampShade = B.post(lounge, 1.4, 1.8, at(-29.5, 7, -4), C.Cream, M.Fabric)
	B.light(lampShade, "Point", 1, 16, C.WarmLight)

	-- the case board: three framed matters on the left wall
	local boardX = -W / 2 + 0.3
	local plate = B.part(
		lounge,
		Vector3.new(0.1, 1.2, 10),
		rot(boardX + 0.2, 14.2, 4, 0),
		C.Ivory,
		{ transparency = 1 }
	)
	B.label(plate, Enum.NormalId.Right, "ACTIVE MATTERS", { color = C.Brass, bold = true })
	for i, caseId in CaseCatalog.order do
		local info = CaseCatalog.cases[caseId]
		local z = 4 + (i - 2) * 5.6
		local frameCF = rot(boardX + 0.2, 9.5, z, 0)
		B.trim(lounge, Vector3.new(0.3, 5.4, 4.6), frameCF, C.Walnut, M.Wood)
		B.trim(lounge, Vector3.new(0.32, 5.0, 4.2), frameCF * CFrame.new(0.02, 0, 0), C.Brass, M.Metal)
		local card = B.trim(
			lounge,
			Vector3.new(0.34, 4.6, 3.8),
			frameCF * CFrame.new(0.04, 0, 0),
			C.Ivory,
			M.SmoothPlastic
		)
		B.label(card, Enum.NormalId.Right, ("CASE %02d\n\n%s"):format(i, info.title), {
			color = C.Navy,
			bold = true,
			ppu = 60,
		})
	end
	local picture = B.trim(lounge, Vector3.new(0.6, 0.3, 15), rot(boardX + 0.6, 12.8, 4, 0), C.Brass, M.Metal)
	B.light(picture, "Surface", 1.2, 10, C.WarmLight, Enum.NormalId.Bottom)
	-- walking players tap this to open the case files
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CaseFilesPrompt"
	prompt.ActionText = "Open case files"
	prompt.ObjectText = "Active Matters"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = plate

	-- Top Associates leaderboard on the right wall, filled in by LobbyService
	local lb = B.folder(model, "Leaderboard")
	B.trim(lb, Vector3.new(0.4, 9.4, 12.4), rot(W / 2 - 0.45, 8.5, 10, 0), C.Walnut, M.Wood)
	B.trim(lb, Vector3.new(0.42, 9.0, 12.0), rot(W / 2 - 0.5, 8.5, 10, 0), C.Brass, M.Metal)
	local lbBoard =
		B.trim(lb, Vector3.new(0.44, 8.6, 11.6), rot(W / 2 - 0.55, 8.5, 10, 0), C.NavyDeep, M.SmoothPlastic)
	lbBoard.Name = "LeaderboardBoard"
	local lbGui = Instance.new("SurfaceGui")
	lbGui.Face = Enum.NormalId.Left
	lbGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	lbGui.PixelsPerStud = 40
	lbGui.LightInfluence = 0.5
	lbGui.MaxDistance = 120
	lbGui.Parent = lbBoard
	local lbTitle = Instance.new("TextLabel")
	lbTitle.Name = "Title"
	lbTitle.BackgroundTransparency = 1
	lbTitle.Size = UDim2.new(1, 0, 0.16, 0)
	lbTitle.Text = "TOP ASSOCIATES"
	lbTitle.TextColor3 = C.Gold
	lbTitle.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
	lbTitle.TextScaled = true
	lbTitle.Parent = lbGui
	local lbList = Instance.new("TextLabel")
	lbList.Name = "List"
	lbList.BackgroundTransparency = 1
	lbList.Position = UDim2.new(0.06, 0, 0.2, 0)
	lbList.Size = UDim2.new(0.88, 0, 0.76, 0)
	lbList.Text = "Win a case to make the board."
	lbList.TextColor3 = C.Ivory
	lbList.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium)
	lbList.TextSize = 22
	lbList.TextWrapped = true
	lbList.TextXAlignment = Enum.TextXAlignment.Left
	lbList.TextYAlignment = Enum.TextYAlignment.Top
	lbList.Parent = lbGui
	local lbLight = B.trim(lb, Vector3.new(0.6, 0.3, 12), rot(W / 2 - 0.8, 13.5, 10, 0), C.Brass, M.Metal)
	B.light(lbLight, "Surface", 1.0, 9, C.WarmLight, Enum.NormalId.Bottom)

	----------------------------------------------------------------- Conference Room B (right, glass)
	local conf = B.folder(model, "ConferenceRoom")
	-- glass wall along x = 12 (z -22..-2)
	local gx = 12
	for i = 0, 3 do
		B.glass(conf, Vector3.new(0.25, H, 5), at(gx, H / 2, -19.5 + i * 5))
		B.trim(conf, Vector3.new(0.4, H, 0.3), at(gx, H / 2, -22 + i * 5), C.Brass, M.Metal)
	end
	B.trim(conf, Vector3.new(0.4, H, 0.3), at(gx, H / 2, -2), C.Brass, M.Metal)
	-- glass wall along z = -2 (x 12..32), with an open doorway at x 13..17
	B.glass(conf, Vector3.new(4, H - 10, 0.25), at(15, 10 + (H - 10) / 2, -2))
	for i = 0, 2 do
		B.glass(conf, Vector3.new(5, H, 0.25), at(19.5 + i * 5, H / 2, -2))
		B.trim(conf, Vector3.new(0.3, H, 0.4), at(17 + i * 5, H / 2, -2), C.Brass, M.Metal)
	end
	B.trim(conf, Vector3.new(20, 0.4, 0.5), at(22, 0.2, -2), C.Espresso, M.Wood)
	B.trim(conf, Vector3.new(0.5, 0.4, 20), at(gx, 0.2, -12), C.Espresso, M.Wood)
	B.trim(conf, Vector3.new(20, 0.3, 0.45), at(22, 10, -2), C.Brass, M.Metal)
	local confSign =
		B.part(conf, Vector3.new(4, 0.9, 0.05), at(22, 7.2, -1.85), C.Ivory, { transparency = 1 })
	B.label(confSign, Enum.NormalId.Back, "CONFERENCE  B", { color = C.Brass, bold = true })
	local confSignOut =
		B.part(conf, Vector3.new(4, 0.9, 0.05), at(22, 7.2, -2.15), C.Ivory, { transparency = 1 })
	B.label(confSignOut, Enum.NormalId.Front, "CONFERENCE  B", { color = C.Brass, bold = true })

	-- carpet, table, chairs
	B.trim(conf, Vector3.new(18, 0.08, 18), at(22, 0.04, -12), C.Cream, M.Fabric)
	B.table(conf, at(22, 0, -12), Vector3.new(11, 3, 5), C.Walnut, C.Espresso, M.Wood)
	B.trim(conf, Vector3.new(10, 0.05, 0.25), at(22, 3.03, -12), C.Brass, M.Metal) -- inlay
	B.chair(conf, rot(18.4, 0, -7.4, 0), C.Leather)
	B.chair(conf, rot(25.6, 0, -7.4, 0), C.Leather)
	B.chair(conf, rot(25.6, 0, -16.6, 180), C.Leather)
	B.chair(conf, rot(14.2, 0, -12, 90), C.Leather)
	-- table dressing: case files, a carafe
	B.trim(
		conf,
		Vector3.new(1.6, 0.15, 2.1),
		at(21, 3.1, -10.6) * CFrame.Angles(0, math.rad(-6), 0),
		C.Navy,
		M.Fabric
	)
	B.trim(
		conf,
		Vector3.new(1.5, 0.05, 2),
		at(21, 3.2, -10.6) * CFrame.Angles(0, math.rad(-6), 0),
		C.Ivory,
		M.SmoothPlastic
	)
	B.trim(
		conf,
		Vector3.new(1.6, 0.15, 2.1),
		at(24.5, 3.1, -13.2) * CFrame.Angles(0, math.rad(10), 0),
		C.Burgundy,
		M.Fabric
	)
	B.post(conf, 1.2, 0.7, at(18.5, 3.17, -12.8), C.Glass, M.Glass)

	-- pendant over the table
	B.trim(conf, Vector3.new(0.08, 4.5, 0.08), at(19, H - 2.25, -12), C.Brass, M.Metal)
	B.trim(conf, Vector3.new(0.08, 4.5, 0.08), at(25, H - 2.25, -12), C.Brass, M.Metal)
	local bar = B.trim(conf, Vector3.new(8, 0.5, 0.8), at(22, H - 4.75, -12), C.Brass, M.Metal)
	B.glow(conf, Vector3.new(7.6, 0.1, 0.5), at(22, H - 5.05, -12))
	B.light(bar, "Surface", 1.6, 14, C.WarmLight, Enum.NormalId.Bottom)

	-- credenza under the window and art on the right wall
	B.trim(conf, Vector3.new(12, 3, 2), at(22, 1.5, -20.5), C.Walnut, M.Wood)
	B.trim(conf, Vector3.new(12.4, 0.2, 2.2), at(22, 3.1, -20.5), C.Ivory, M.Marble)
	for i = 0, 2 do
		B.trim(conf, Vector3.new(0.1, 2.2, 0.05), at(18 + i * 4, 1.5, -19.47), C.Brass, M.Metal)
	end
	B.trim(conf, Vector3.new(0.3, 1.6, 2.2), at(18.5, 4, -20.5), C.Navy, M.Fabric)
	B.trim(conf, Vector3.new(0.3, 1.4, 2.0), at(18.85, 3.9, -20.5), C.Burgundy, M.Fabric)
	B.trim(conf, Vector3.new(0.3, 1.7, 2.1), at(19.2, 4.05, -20.5), C.Cream, M.Fabric)
	B.plant(conf, at(29.5, 0, -19.5), 0.8)
	local art = B.trim(conf, Vector3.new(0.3, 6, 9), at(W / 2 - 0.2, 8, -12), C.Navy, M.Fabric)
	B.trim(conf, Vector3.new(0.35, 6.4, 9.4), at(W / 2 - 0.15, 8, -12), C.Brass, M.Metal)
	B.trim(conf, Vector3.new(0.4, 3.5, 2.2), at(W / 2 - 0.3, 8.6, -14), C.Brass, M.Metal)
	B.trim(conf, Vector3.new(0.4, 1.8, 4.6), at(W / 2 - 0.3, 7, -10.6), C.Cream, M.SmoothPlastic)
	B.trim(conf, Vector3.new(0.42, 0.25, 6.5), at(W / 2 - 0.32, 9.5, -12), C.Ivory, M.SmoothPlastic)
	art.Name = "Art"

	----------------------------------------------------------------- greenery + entry dressing
	B.plant(decor, at(-29.5, 0, 19), 1.1)
	B.plant(decor, at(-8.5, 0, 19.5), 0.9)
	B.plant(decor, at(8.5, 0, 19.5), 0.9)
	B.plant(decor, at(29, 0, 19), 1.1)
	B.plant(decor, at(-13.5, 0, -19.5), 1.0)
	B.plant(decor, at(13.8, 0, 1.2), 0.8)

	-- bench seating by the entrance (right)
	B.trim(decor, Vector3.new(8, 1.6, 2.4), at(22, 0.8, 18), C.Espresso, M.Wood)
	B.trim(decor, Vector3.new(7.6, 0.4, 2.2), at(22, 1.8, 18), C.Cream, M.Leather)
	-- wall clock above the doors
	local clock = B.cylinder(
		decor,
		0.3,
		2.4,
		at(0, 13.5, frontZ - 0.7) * CFrame.Angles(0, math.rad(90), 0),
		C.Ivory,
		M.SmoothPlastic
	)
	B.cylinder(
		decor,
		0.25,
		2.7,
		at(0, 13.5, frontZ - 0.6) * CFrame.Angles(0, math.rad(90), 0),
		C.Brass,
		M.Metal
	)
	B.trim(decor, Vector3.new(0.12, 0.8, 0.05), at(0, 13.8, frontZ - 0.88), C.Espresso, M.SmoothPlastic)
	B.trim(decor, Vector3.new(0.6, 0.12, 0.05), at(0.25, 13.5, frontZ - 0.88), C.Espresso, M.SmoothPlastic)
	clock.Name = "Clock"

	----------------------------------------------------------------- spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(4, 1, 4)
	spawn.CFrame = O * CFrame.new(StageLayout.SpawnOffset) * CFrame.new(0, -0.45, 0)
	spawn.Transparency = 1
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = model

	return model
end

return Office
