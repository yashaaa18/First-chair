--[[
	Palette — the single source of truth for FIRST CHAIR's colours.
	Espresso & walnut woods, deep navy, ivory/cream, warm brass.
]]

local Palette = {
	-- Woods
	Espresso = Color3.fromRGB(46, 31, 24),
	Walnut = Color3.fromRGB(92, 60, 42),
	WalnutLight = Color3.fromRGB(122, 84, 58),
	Oak = Color3.fromRGB(160, 120, 84),

	-- Navy
	Navy = Color3.fromRGB(22, 33, 52),
	NavyDeep = Color3.fromRGB(13, 20, 33),
	NavySoft = Color3.fromRGB(38, 52, 76),

	-- Ivory / cream
	Ivory = Color3.fromRGB(246, 241, 231),
	Cream = Color3.fromRGB(232, 222, 202),
	Stone = Color3.fromRGB(205, 196, 180),
	Plaster = Color3.fromRGB(226, 218, 204),

	-- Metals
	Brass = Color3.fromRGB(182, 146, 92),
	BrassDark = Color3.fromRGB(140, 108, 64),
	Gold = Color3.fromRGB(205, 172, 112),

	-- Accents
	Leather = Color3.fromRGB(70, 38, 30),
	Burgundy = Color3.fromRGB(118, 42, 46),
	Sage = Color3.fromRGB(96, 118, 88),
	Leaf = Color3.fromRGB(64, 92, 60),
	Charcoal = Color3.fromRGB(40, 40, 44),
	Glass = Color3.fromRGB(190, 214, 222),
	WarmLight = Color3.fromRGB(255, 214, 160),

	-- UI feedback
	Success = Color3.fromRGB(122, 158, 112),
	Danger = Color3.fromRGB(176, 78, 72),
}

return Palette
