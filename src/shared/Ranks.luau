--[[
	Ranks — grading and career progression rules.
	Shared so the client can *display* them; the server is the only side
	that ever *awards* anything.
]]

local Ranks = {}

-- Points awarded for a case by its best grade.
Ranks.GradePoints = {
	S = 50,
	A = 40,
	B = 30,
	C = 20,
}

-- Career titles, unlocked by total promotion points.
Ranks.Titles = {
	{ points = 0, title = "Junior Associate" },
	{ points = 40, title = "Associate" },
	{ points = 90, title = "Senior Associate" },
	{ points = 140, title = "First Chair" },
}

-- Points for a scored step, by how many tries it took.
Ranks.StepPoints = { 100, 60, 35 }
Ranks.StepPointsFloor = 20

function Ranks.pointsForTries(tries: number): number
	return Ranks.StepPoints[tries] or Ranks.StepPointsFloor
end

function Ranks.gradeFor(percent: number): string
	if percent >= 95 then
		return "S"
	elseif percent >= 80 then
		return "A"
	elseif percent >= 60 then
		return "B"
	end
	return "C"
end

function Ranks.titleFor(points: number): string
	local title = Ranks.Titles[1].title
	for _, entry in Ranks.Titles do
		if points >= entry.points then
			title = entry.title
		end
	end
	return title
end

function Ranks.nextTitle(points: number): (string?, number?)
	for _, entry in Ranks.Titles do
		if points < entry.points then
			return entry.title, entry.points
		end
	end
	return nil, nil
end

-- Higher is better.
local ORDER = { C = 1, B = 2, A = 3, S = 4 }
function Ranks.better(a: string?, b: string?): boolean
	return (ORDER[a or ""] or 0) > (ORDER[b or ""] or 0)
end

return Ranks
