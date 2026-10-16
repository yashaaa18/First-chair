--[[
	StageLayout — where everything stands.

	The server uses these numbers to build furniture around the marks; the client
	uses the same numbers to place actors and frame camera shots, so the two can
	never drift apart.

	Spots are floor-level CFrames facing the direction the actor looks.
	`side` (+1 / -1) picks which shoulder the close-up camera sits over.
]]

local StageLayout = {}

StageLayout.Origins = {
	office = CFrame.new(0, 0, 0),
	court = CFrame.new(0, 0, 400),
}

export type Spot = { location: string, cf: CFrame, side: number }
export type Shot = { location: string, cf: CFrame, fov: number }

local function facing(location: string, pos: Vector3, target: Vector3): CFrame
	local origin = StageLayout.Origins[location]
	local p = origin * pos
	local t = origin * Vector3.new(target.X, pos.Y, target.Z)
	return CFrame.lookAt(p, t)
end

local function spot(location: string, pos: Vector3, target: Vector3, side: number?): Spot
	return { location = location, cf = facing(location, pos, target), side = side or 1 }
end

local function shot(location: string, eye: Vector3, target: Vector3, fov: number?): Shot
	local origin = StageLayout.Origins[location]
	return { location = location, cf = CFrame.lookAt(origin * eye, origin * target), fov = fov or 50 }
end

StageLayout.Spots = {
	-- Valence Legal: lobby
	office_entry = spot("office", Vector3.new(0, 0, 7), Vector3.new(0, 0, -20), -1),
	office_theo = spot("office", Vector3.new(1.5, 0, -13.5), Vector3.new(0, 0, 10), 1),

	-- Valence Legal: Conference Room B (glass room, right side)
	office_meeting_head = spot("office", Vector3.new(29, 0, -12), Vector3.new(0, 0, -12), 1),
	office_meeting_player = spot("office", Vector3.new(21, 0, -7.6), Vector3.new(21, 0, -30), -1),
	office_meeting_guest = spot("office", Vector3.new(21.5, 0, -16.6), Vector3.new(21.5, 0, 10), 1),
	office_meeting_guest2 = spot("office", Vector3.new(16, 0, -16.6), Vector3.new(16, 0, 10), -1),

	-- Northbridge Civil Court
	court_judge = spot("court", Vector3.new(0, 4, -38.5), Vector3.new(0, 0, 10), 1),
	court_witness = spot("court", Vector3.new(15, 1.5, -27), Vector3.new(-2, 0, -12), -1),
	court_defense_player = spot("court", Vector3.new(-9, 0, -12.5), Vector3.new(-9, 0, -40), -1),
	court_defense_second = spot("court", Vector3.new(-5.4, 0, -12.5), Vector3.new(-5.4, 0, -40), 1),
	court_defense_client = spot("court", Vector3.new(-12.6, 0, -12.5), Vector3.new(-12.6, 0, -40), -1),
	court_plaintiff_counsel = spot("court", Vector3.new(7.5, 0, -12.5), Vector3.new(7.5, 0, -40), 1),
	court_plaintiff_party = spot("court", Vector3.new(11.2, 0, -12.5), Vector3.new(11.2, 0, -40), 1),
}

StageLayout.Shots = {
	office_menu = shot("office", Vector3.new(-22, 7.5, 17), Vector3.new(4, 5, -16), 55),
	office_menu_end = shot("office", Vector3.new(-14, 7, 17.5), Vector3.new(8, 5, -16), 55),
	office_entrance = shot("office", Vector3.new(0, 6.5, 19), Vector3.new(0, 5, -14), 52),
	office_meeting_wide = shot("office", Vector3.new(13.6, 8.5, -3), Vector3.new(25, 2.5, -14), 58),
	office_lounge = shot("office", Vector3.new(-6, 7, 10), Vector3.new(-26, 4, 0), 55),

	court_wide = shot("court", Vector3.new(0, 13, 36), Vector3.new(0, 6, -36), 50),
	court_judge_low = shot("court", Vector3.new(0, 7.4, -26), Vector3.new(0, 8.6, -38.5), 42),
	court_well = shot("court", Vector3.new(-16, 9, -2), Vector3.new(8, 4, -28), 50),
	court_defense = shot("court", Vector3.new(-3, 6.5, -27), Vector3.new(-9, 4.2, -12.5), 48),
	court_plaintiff = shot("court", Vector3.new(3, 6.5, -27), Vector3.new(9, 4.2, -12.5), 48),
	court_gallery = shot("court", Vector3.new(20, 10, 22), Vector3.new(-6, 4, -20), 55),
}

StageLayout.LocationTitles = {
	office = "VALENCE LEGAL  ·  NORTHBRIDGE",
	court = "NORTHBRIDGE CIVIL COURT  ·  ROOM 4",
}

StageLayout.SpawnOffset = Vector3.new(0, 0, 12) -- office-relative player spawn

return StageLayout
