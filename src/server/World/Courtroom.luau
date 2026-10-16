--[[
	Courtroom — Northbridge Civil Court, Room 4.
	Interior: x -30..30, z -46..42, height 28. The bench is at the -z end.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local StageLayout = require(Shared.StageLayout)
local B = require(script.Parent.Builder)

local C = B.Palette
local M = Enum.Material

local Courtroom = {}

local HALF_W = 30
local FRONT_Z, BACK_Z = -46, 42
local H = 28
local WAINSCOT = 8
local WINDOWS = { -30, -16, -2, 12, 26 } -- z centres of the tall side windows
local WINDOW_W = 6

function Courtroom.build(root: Instance)
	local O = StageLayout.Origins.court
	local function at(x: number, y: number, z: number): CFrame
		return O * CFrame.new(x, y, z)
	end

	local model = B.folder(root, "Courtroom")
	local shell = B.folder(model, "Shell")
	local decor = B.folder(model, "Decor")
	local depth = BACK_Z - FRONT_Z
	local midZ = (BACK_Z + FRONT_Z) / 2

	----------------------------------------------------------------- floor + ceiling
	B.solid(shell, Vector3.new(HALF_W * 2 + 2, 1, depth + 2), at(0, -0.5, midZ), C.Walnut, M.WoodPlanks)
	-- lighter gallery floor and a navy aisle runner
	B.trim(
		decor,
		Vector3.new(HALF_W * 2, 0.06, BACK_Z + 6),
		at(0, 0.03, (BACK_Z - 6) / 2),
		C.Oak,
		M.WoodPlanks
	)
	B.trim(decor, Vector3.new(5, 0.1, BACK_Z + 6), at(0, 0.05, (BACK_Z - 6) / 2), C.Navy, M.Fabric)
	B.trim(decor, Vector3.new(5.6, 0.08, BACK_Z + 6), at(0, 0.04, (BACK_Z - 6) / 2), C.Brass, M.Metal)
	-- the well: an inlaid border
	B.trim(decor, Vector3.new(40, 0.06, 0.6), at(0, 0.04, -8), C.Espresso, M.Wood)

	B.solid(shell, Vector3.new(HALF_W * 2 + 2, 1, depth + 2), at(0, H + 0.5, midZ), C.Plaster, M.Plaster)
	-- coffered ceiling: cross beams + two long beams
	for z = FRONT_Z + 10, BACK_Z - 4, 12 do
		B.trim(decor, Vector3.new(HALF_W * 2, 1.4, 1.2), at(0, H - 0.7, z), C.Walnut, M.Wood)
	end
	for _, x in { -10, 10 } do
		B.trim(decor, Vector3.new(1.2, 1.4, depth), at(x, H - 0.7, midZ), C.Walnut, M.Wood)
	end
	-- recessed glow panels between beams over the centre
	for z = -6, BACK_Z - 10, 12 do
		B.glow(decor, Vector3.new(16, 0.1, 8), at(0, H - 0.08, z), C.Ivory)
	end

	----------------------------------------------------------------- side walls with tall windows
	for _, side in { -1, 1 } do
		local x = side * (HALF_W + 0.5)
		-- lower wall + walnut wainscot
		B.solid(
			shell,
			Vector3.new(1, WAINSCOT + 2, depth + 2),
			at(x, (WAINSCOT + 2) / 2, midZ),
			C.Plaster,
			M.Plaster
		)
		B.trim(
			decor,
			Vector3.new(0.4, WAINSCOT, depth),
			at(x - side * 0.7, WAINSCOT / 2, midZ),
			C.Walnut,
			M.Wood
		)
		B.trim(
			decor,
			Vector3.new(0.6, 0.35, depth),
			at(x - side * 0.85, WAINSCOT + 0.1, midZ),
			C.Brass,
			M.Metal
		)
		-- raised panels on the wainscot
		for z = FRONT_Z + 4, BACK_Z - 4, 6 do
			B.trim(
				decor,
				Vector3.new(0.2, WAINSCOT - 3, 4.4),
				at(x - side * 0.95, WAINSCOT / 2, z),
				C.WalnutLight,
				M.Wood
			)
		end
		-- header above the windows
		B.solid(
			shell,
			Vector3.new(1, H - 24, depth + 2),
			at(x, 24 + (H - 24) / 2, midZ),
			C.Plaster,
			M.Plaster
		)
		B.trim(decor, Vector3.new(0.8, 1, depth), at(x - side * 0.9, H - 0.5, midZ), C.Espresso, M.Wood) -- crown
		-- piers between windows + glass + sills
		local edges = { FRONT_Z - 1 }
		for _, wz in WINDOWS do
			table.insert(edges, wz - WINDOW_W / 2)
			table.insert(edges, wz + WINDOW_W / 2)
		end
		table.insert(edges, BACK_Z + 1)
		for i = 1, #edges, 2 do
			local z0, z1 = edges[i], edges[i + 1]
			B.solid(
				shell,
				Vector3.new(1, 24 - (WAINSCOT + 2), z1 - z0),
				at(x, (WAINSCOT + 2 + 24) / 2, (z0 + z1) / 2),
				C.Plaster,
				M.Plaster
			)
		end
		for _, wz in WINDOWS do
			B.glass(
				shell,
				Vector3.new(0.3, 24 - (WAINSCOT + 2), WINDOW_W),
				at(x, (WAINSCOT + 2 + 24) / 2, wz)
			)
			B.trim(
				decor,
				Vector3.new(1.4, 0.4, WINDOW_W + 0.6),
				at(x - side * 0.3, WAINSCOT + 2, wz),
				C.Walnut,
				M.Wood
			)
			B.trim(
				decor,
				Vector3.new(0.5, 24 - (WAINSCOT + 2), 0.25),
				at(x - side * 0.1, (WAINSCOT + 2 + 24) / 2, wz),
				C.Brass,
				M.Metal
			)
			B.trim(decor, Vector3.new(0.5, 0.25, WINDOW_W), at(x - side * 0.1, 19, wz), C.Brass, M.Metal)
			-- walnut pilaster beside each window
			B.trim(
				decor,
				Vector3.new(0.8, H - WAINSCOT - 1, 1.2),
				at(x - side * 0.9, (H + WAINSCOT) / 2, wz + WINDOW_W / 2 + 2),
				C.Walnut,
				M.Wood
			)
		end
	end

	----------------------------------------------------------------- back (entrance) wall
	local backWallZ = BACK_Z + 0.5
	B.solid(shell, Vector3.new(HALF_W * 2 + 2, H, 1), at(0, H / 2, backWallZ), C.Plaster, M.Plaster)
	B.trim(decor, Vector3.new(HALF_W * 2, WAINSCOT, 0.4), at(0, WAINSCOT / 2, BACK_Z - 0.2), C.Walnut, M.Wood)
	B.trim(decor, Vector3.new(HALF_W * 2, 0.35, 0.6), at(0, WAINSCOT + 0.1, BACK_Z - 0.3), C.Brass, M.Metal)
	-- double doors
	B.trim(decor, Vector3.new(8, 12, 0.5), at(0, 6, BACK_Z - 0.45), C.Espresso, M.Wood)
	for _, dx in { -2, 2 } do
		B.trim(decor, Vector3.new(3.6, 11.4, 0.3), at(dx, 5.8, BACK_Z - 0.75), C.Walnut, M.Wood)
		B.trim(decor, Vector3.new(0.15, 2, 0.2), at(dx * 0.15, 5.5, BACK_Z - 1), C.Brass, M.Metal)
	end
	-- clock above the doors
	B.cylinder(
		decor,
		0.3,
		3.2,
		at(0, 17, BACK_Z - 0.3) * CFrame.Angles(0, math.rad(90), 0),
		C.Ivory,
		M.SmoothPlastic
	)
	B.cylinder(
		decor,
		0.25,
		3.6,
		at(0, 17, BACK_Z - 0.2) * CFrame.Angles(0, math.rad(90), 0),
		C.Brass,
		M.Metal
	)
	B.trim(decor, Vector3.new(0.15, 1.1, 0.05), at(0, 17.4, BACK_Z - 0.5), C.Espresso, M.SmoothPlastic)
	B.trim(decor, Vector3.new(0.8, 0.15, 0.05), at(-0.35, 17, BACK_Z - 0.5), C.Espresso, M.SmoothPlastic)

	----------------------------------------------------------------- front (bench) wall
	local frontWallZ = FRONT_Z - 0.5
	B.solid(shell, Vector3.new(HALF_W * 2 + 2, H, 1), at(0, H / 2, frontWallZ), C.Walnut, M.Wood)
	-- fluted walnut pilasters
	for x = -27, 27, 6 do
		if math.abs(x) > 9 then
			B.trim(decor, Vector3.new(1.4, H - 2, 0.6), at(x, (H - 2) / 2, FRONT_Z + 0.3), C.Espresso, M.Wood)
			B.trim(decor, Vector3.new(1.8, 0.6, 0.9), at(x, H - 2.3, FRONT_Z + 0.4), C.Brass, M.Metal)
		end
	end
	-- navy dossal panel framed in brass, with the city seal
	B.trim(decor, Vector3.new(16, 18, 0.4), at(0, 13, FRONT_Z + 0.3), C.Navy, M.Fabric)
	for _, sx in { -8.1, 8.1 } do
		B.trim(decor, Vector3.new(0.4, 18.4, 0.6), at(sx, 13, FRONT_Z + 0.35), C.Brass, M.Metal)
	end
	B.trim(decor, Vector3.new(16.6, 0.4, 0.6), at(0, 22.2, FRONT_Z + 0.35), C.Brass, M.Metal)
	B.trim(decor, Vector3.new(18, 1.4, 1.2), at(0, 23.2, FRONT_Z + 0.6), C.Walnut, M.Wood) -- pediment
	local sealZ = FRONT_Z + 0.6
	B.cylinder(decor, 0.3, 7.6, at(0, 15.5, sealZ) * CFrame.Angles(0, math.rad(90), 0), C.Brass, M.Metal)
	B.cylinder(
		decor,
		0.35,
		6.4,
		at(0, 15.5, sealZ + 0.05) * CFrame.Angles(0, math.rad(90), 0),
		C.NavyDeep,
		M.SmoothPlastic
	)
	local sealText =
		B.part(decor, Vector3.new(5.2, 5.2, 0.05), at(0, 15.5, sealZ + 0.26), C.Navy, { transparency = 1 })
	B.label(
		sealText,
		Enum.NormalId.Back,
		"NORTHBRIDGE\nCIVIL COURT",
		{ color = C.Gold, bold = true, ppu = 50 }
	)
	local motto =
		B.part(decor, Vector3.new(12, 1, 0.05), at(0, 9.6, FRONT_Z + 0.55), C.Navy, { transparency = 1 })
	B.label(motto, Enum.NormalId.Back, "TRUTH  ·  EVIDENCE  ·  FAIRNESS", {
		color = C.Gold,
		font = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold),
	})

	----------------------------------------------------------------- judge's bench
	local bench = B.folder(model, "Bench")
	local platformH = 4
	B.solid(bench, Vector3.new(24, platformH, 11), at(0, platformH / 2, FRONT_Z + 5.5), C.Espresso, M.Wood)
	-- step down to the clerk level
	B.solid(bench, Vector3.new(26, 1, 2), at(0, 0.5, FRONT_Z + 11.6), C.Walnut, M.Wood)
	-- bench front: walnut with lighter raised panels and brass rails
	local benchFrontZ = -35
	local benchTop = platformH + 3
	B.solid(bench, Vector3.new(18, benchTop, 1.4), at(0, benchTop / 2, benchFrontZ), C.Walnut, M.Wood)
	for _, sx in { -9.4, 9.4 } do
		B.solid(bench, Vector3.new(1, benchTop, 4), at(sx, benchTop / 2, benchFrontZ - 1.3), C.Walnut, M.Wood)
	end
	for i = -1, 1 do
		B.trim(
			bench,
			Vector3.new(4.6, benchTop - 2.6, 0.2),
			at(i * 5.6, benchTop / 2 - 0.2, benchFrontZ + 0.75),
			C.WalnutLight,
			M.Wood
		)
		B.trim(
			bench,
			Vector3.new(4.2, 0.12, 0.25),
			at(i * 5.6, benchTop - 1.6, benchFrontZ + 0.8),
			C.Brass,
			M.Metal
		)
	end
	B.trim(bench, Vector3.new(19.2, 0.45, 3.4), at(0, benchTop + 0.22, benchFrontZ - 0.9), C.Espresso, M.Wood)
	B.trim(bench, Vector3.new(19.4, 0.15, 0.25), at(0, benchTop + 0.05, benchFrontZ + 0.72), C.Brass, M.Metal)
	B.trim(bench, Vector3.new(18.4, 0.3, 0.3), at(0, 0.15, benchFrontZ + 0.75), C.Brass, M.Metal)
	local nameplate =
		B.trim(bench, Vector3.new(4, 0.6, 0.25), at(0, benchTop - 0.7, benchFrontZ + 0.82), C.Brass, M.Metal)
	B.label(nameplate, Enum.NormalId.Back, "JUDGE ROWAN", { color = C.NavyDeep, bold = true, ppu = 60 })
	-- tall leather chair framing the judge
	local chairZ = -41.4
	B.trim(bench, Vector3.new(4.2, 7.8, 0.9), at(0, platformH + 4.4, chairZ), C.Navy, M.Leather)
	B.trim(bench, Vector3.new(4.6, 0.5, 1.1), at(0, platformH + 8.4, chairZ), C.Brass, M.Metal)
	-- gavel + block, papers, banker's lamp
	B.cylinder(bench, 0.25, 1.1, at(-3, benchTop + 0.55, benchFrontZ - 1.2), C.Espresso, M.Wood)
	B.trim(
		bench,
		Vector3.new(1.4, 0.35, 0.35),
		at(-2.4, benchTop + 0.65, benchFrontZ - 1.6) * CFrame.Angles(0, math.rad(30), 0),
		C.Espresso,
		M.Wood
	)
	B.trim(
		bench,
		Vector3.new(1.8, 0.05, 2.3),
		at(3, benchTop + 0.47, benchFrontZ - 1.2) * CFrame.Angles(0, math.rad(-8), 0),
		C.Ivory,
		M.SmoothPlastic
	)
	B.post(bench, 1, 0.12, at(-6, benchTop + 0.45, benchFrontZ - 1.4), C.Brass, M.Metal)
	local lampHead =
		B.trim(bench, Vector3.new(1.8, 0.45, 0.7), at(-6, benchTop + 1.5, benchFrontZ - 1.3), C.Navy, M.Glass)
	B.light(lampHead, "Spot", 0.8, 8, C.WarmLight, Enum.NormalId.Bottom)
	-- plants either side of the bench
	B.plant(decor, at(-13.5, 0, -42), 1.2)
	B.plant(decor, at(13.5, 0, -42), 1.2)

	-- clerk's desk (left, lower)
	B.solid(bench, Vector3.new(7, 3.6, 3), at(-12.5, 1.8, -31), C.Walnut, M.Wood)
	B.trim(bench, Vector3.new(7.4, 0.3, 3.4), at(-12.5, 3.75, -31), C.Espresso, M.Wood)
	B.trim(bench, Vector3.new(7.1, 0.2, 0.2), at(-12.5, 3.3, -29.45), C.Brass, M.Metal)
	B.trim(
		bench,
		Vector3.new(1.6, 1.1, 0.12),
		at(-11.5, 4.5, -31.6) * CFrame.Angles(math.rad(-10), 0, 0),
		C.Charcoal,
		M.SmoothPlastic
	)

	----------------------------------------------------------------- witness stand
	local stand = B.folder(model, "WitnessStand")
	local wcf = StageLayout.Spots.court_witness.cf * CFrame.new(0, -1.5, 0) -- floor-level frame
	B.solid(stand, Vector3.new(6, 1.5, 6), wcf * CFrame.new(0, 0.75, 0.5), C.Espresso, M.Wood)
	B.solid(stand, Vector3.new(6, 3.4, 0.5), wcf * CFrame.new(0, 1.5 + 1.7, -2.3), C.Walnut, M.Wood)
	for _, sx in { -2.75, 2.75 } do
		B.solid(stand, Vector3.new(0.5, 3.4, 4.5), wcf * CFrame.new(sx, 1.5 + 1.7, -0.3), C.Walnut, M.Wood)
		B.trim(stand, Vector3.new(0.7, 0.25, 4.7), wcf * CFrame.new(sx, 5.0, -0.3), C.Brass, M.Metal)
	end
	B.trim(stand, Vector3.new(6.2, 0.25, 0.7), wcf * CFrame.new(0, 5.0, -2.3), C.Brass, M.Metal)
	B.trim(stand, Vector3.new(4.2, 2.2, 0.2), wcf * CFrame.new(0, 3.2, -2.6), C.WalnutLight, M.Wood)
	-- microphone
	B.trim(
		stand,
		Vector3.new(0.1, 1.4, 0.1),
		wcf * CFrame.new(0.9, 5.7, -2.1) * CFrame.Angles(math.rad(-25), 0, 0),
		C.Charcoal,
		M.Metal
	)
	B.ball(stand, 0.35, wcf * CFrame.new(0.9, 6.35, -1.8), C.Charcoal, M.Metal)

	----------------------------------------------------------------- counsel tables
	local tables = B.folder(model, "CounselTables")
	for _, side in { -1, 1 } do
		local cx = side * 9
		B.table(tables, at(cx, 0, -16), Vector3.new(12, 3, 4), C.Walnut, C.Espresso, M.Wood)
		-- modesty panel facing the bench
		B.trim(tables, Vector3.new(11, 2.2, 0.2), at(cx, 1.6, -17.7), C.Walnut, M.Wood)
		B.trim(tables, Vector3.new(11, 0.12, 0.25), at(cx, 2.5, -17.8), C.Brass, M.Metal)
		-- papers and folders
		B.trim(
			tables,
			Vector3.new(1.6, 0.12, 2.1),
			at(cx - 3, 3.07, -15.4) * CFrame.Angles(0, math.rad(side * 6), 0),
			C.Navy,
			M.Fabric
		)
		B.trim(
			tables,
			Vector3.new(1.5, 0.05, 2),
			at(cx + 0.5, 3.04, -15.2) * CFrame.Angles(0, math.rad(-side * 4), 0),
			C.Ivory,
			M.SmoothPlastic
		)
		B.trim(
			tables,
			Vector3.new(1.6, 0.18, 2.1),
			at(cx + 3.4, 3.1, -15.6),
			if side < 0 then C.Burgundy else C.Charcoal,
			M.Fabric
		)
		B.post(tables, 0.9, 0.5, at(cx - 4.6, 3.0, -16.6), C.Glass, M.Glass)
		-- chairs behind the counsel (pulled back so actors stand clear)
		for _, dx in { -3.6, 0, 3.6 } do
			B.chair(tables, at(cx + dx, 0, -9.6), C.Leather)
		end
	end

	----------------------------------------------------------------- the bar (railing)
	local bar = B.folder(model, "Bar")
	local barZ = -6
	for _, side in { -1, 1 } do
		local len = HALF_W - 3
		local cx = side * (3 + len / 2)
		B.trim(bar, Vector3.new(len, 3, 0.5), at(cx, 1.5, barZ), C.Walnut, M.Wood)
		B.trim(bar, Vector3.new(len, 0.35, 0.9), at(cx, 3.15, barZ), C.Espresso, M.Wood)
		B.trim(bar, Vector3.new(len, 0.12, 0.95), at(cx, 3.36, barZ), C.Brass, M.Metal)
		for i = 0, math.floor(len / 3) - 1 do
			B.trim(
				bar,
				Vector3.new(2.2, 1.8, 0.1),
				at(side * (4.6 + i * 3), 1.6, barZ - 0.3),
				C.WalnutLight,
				M.Wood
			)
		end
		B.post(bar, 4, 0.8, at(side * 3, 0, barZ), C.Espresso, M.Wood)
		B.ball(bar, 0.9, at(side * 3, 4.2, barZ), C.Brass, M.Metal)
	end

	----------------------------------------------------------------- gallery pews
	local gallery = B.folder(model, "Gallery")
	for row = 0, 5 do
		local z = 0 + row * 5.5
		for _, side in { -1, 1 } do
			local cx = side * 15
			local len = 21
			B.trim(gallery, Vector3.new(len, 0.5, 2.2), at(cx, 1.8, z), C.Walnut, M.Wood)
			B.trim(gallery, Vector3.new(len, 2.8, 0.4), at(cx, 3.2, z + 1.2), C.Walnut, M.Wood)
			B.trim(gallery, Vector3.new(len, 0.25, 0.6), at(cx, 4.65, z + 1.2), C.Espresso, M.Wood)
			B.trim(gallery, Vector3.new(len - 0.4, 0.15, 1.8), at(cx, 2.1, z - 0.1), C.Navy, M.Fabric)
			for _, ex in { -len / 2, len / 2 } do
				B.trim(gallery, Vector3.new(0.4, 4.2, 2.8), at(cx + ex, 2.1, z + 0.3), C.Espresso, M.Wood)
			end
		end
	end

	----------------------------------------------------------------- law library shelves (left of the well)
	local shelves = B.folder(model, "Library")
	local shelfX = -HALF_W + 1.2
	B.trim(shelves, Vector3.new(1.6, 9, 12), at(shelfX, 4.5, -24), C.Espresso, M.Wood)
	local bookColors = { C.Navy, C.Burgundy, C.Leather, C.Sage, C.NavySoft, C.BrassDark }
	for level = 0, 3 do
		B.trim(
			shelves,
			Vector3.new(1.8, 0.25, 12),
			at(shelfX + 0.1, 0.9 + level * 2.1, -24),
			C.Walnut,
			M.Wood
		)
		for b = 0, 2 do
			local color = bookColors[((level + b) % #bookColors) + 1]
			B.trim(
				shelves,
				Vector3.new(1.2, 1.5, 3.4),
				at(shelfX + 0.3, 1.8 + level * 2.1, -28.2 + b * 4.1),
				color,
				M.Fabric
			)
		end
	end
	B.trim(shelves, Vector3.new(1.6, 9, 12), at(-shelfX, 4.5, -24), C.Espresso, M.Wood)
	for level = 0, 3 do
		B.trim(
			shelves,
			Vector3.new(1.8, 0.25, 12),
			at(-shelfX - 0.1, 0.9 + level * 2.1, -24),
			C.Walnut,
			M.Wood
		)
		for b = 0, 2 do
			local color = bookColors[((level + b + 2) % #bookColors) + 1]
			B.trim(
				shelves,
				Vector3.new(1.2, 1.5, 3.4),
				at(-shelfX - 0.3, 1.8 + level * 2.1, -28.2 + b * 4.1),
				color,
				M.Fabric
			)
		end
	end

	----------------------------------------------------------------- lighting
	-- three brass pendants down the gallery
	for _, z in { 4, 16, 28 } do
		B.trim(decor, Vector3.new(0.1, 7, 0.1), at(0, H - 3.5, z), C.Brass, M.Metal)
		local shade =
			B.cylinder(decor, 0.6, 4, at(0, H - 7.3, z) * CFrame.Angles(0, 0, math.rad(90)), C.Brass, M.Metal)
		B.cylinder(
			decor,
			0.15,
			3.4,
			at(0, H - 7.65, z) * CFrame.Angles(0, 0, math.rad(90)),
			C.WarmLight,
			M.Neon
		)
		B.light(shade, "Point", 1.1, 26, C.WarmLight)
	end
	-- the well: two broad ceiling washes
	for _, z in { -32, -18 } do
		local panel = B.glow(decor, Vector3.new(14, 0.1, 6), at(0, H - 0.1, z), C.Ivory)
		B.light(panel, "Surface", 1.4, 30, C.WarmLight, Enum.NormalId.Bottom)
	end
	-- sconces between the side windows (glow only)
	for _, side in { -1, 1 } do
		for _, wz in WINDOWS do
			B.sconce(
				decor,
				at(side * (HALF_W - 1.2), 13, wz - WINDOW_W / 2 - 1.5)
					* CFrame.Angles(0, math.rad(side * 90), 0),
				false
			)
		end
	end

	return model
end

return Courtroom
