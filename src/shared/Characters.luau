--[[
	Characters — the cast. Names/roles are shown in dialogue; `look` is used by the
	server to build simple, consistent, stylised NPC models (no external assets).

	hairStyle: "short" | "bob" | "long" | "bun" | "slick" | "crop" | "none"
]]

local Palette = require(script.Parent.Palette)

export type Look = {
	skin: Color3,
	hair: Color3,
	hairStyle: string,
	top: Color3,
	bottom: Color3,
	collar: Color3?,
	tie: Color3?,
	scale: number?,
}

export type Character = {
	id: string,
	name: string,
	role: string,
	look: Look,
}

local SKIN = {
	Fair = Color3.fromRGB(234, 198, 170),
	Light = Color3.fromRGB(222, 180, 146),
	Tan = Color3.fromRGB(196, 146, 108),
	Brown = Color3.fromRGB(150, 102, 72),
	Deep = Color3.fromRGB(102, 68, 50),
}

local HAIR = {
	Black = Color3.fromRGB(28, 24, 24),
	Dark = Color3.fromRGB(52, 36, 28),
	Auburn = Color3.fromRGB(118, 58, 36),
	Blonde = Color3.fromRGB(196, 160, 104),
	Grey = Color3.fromRGB(176, 172, 166),
	Silver = Color3.fromRGB(210, 208, 204),
}

local Characters: { [string]: Character } = {
	mara = {
		id = "mara",
		name = "Mara Quinn",
		role = "Senior Partner",
		look = {
			skin = SKIN.Tan,
			hair = HAIR.Dark,
			hairStyle = "bun",
			top = Palette.Navy,
			bottom = Palette.Navy,
			collar = Palette.Ivory,
		},
	},
	rowan = {
		id = "rowan",
		name = "Judge Rowan",
		role = "Presiding Judge",
		look = {
			skin = SKIN.Brown,
			hair = HAIR.Silver,
			hairStyle = "crop",
			top = Color3.fromRGB(20, 20, 24),
			bottom = Color3.fromRGB(20, 20, 24),
			collar = Palette.Ivory,
		},
	},
	voss = {
		id = "voss",
		name = "Adrian Voss",
		role = "Opposing Counsel",
		look = {
			skin = SKIN.Fair,
			hair = HAIR.Blonde,
			hairStyle = "slick",
			top = Palette.Charcoal,
			bottom = Palette.Charcoal,
			collar = Palette.Ivory,
			tie = Palette.Burgundy,
		},
	},
	theo = {
		id = "theo",
		name = "Theo Marsh",
		role = "Reception",
		look = {
			skin = SKIN.Deep,
			hair = HAIR.Black,
			hairStyle = "crop",
			top = Palette.Walnut,
			bottom = Palette.Espresso,
			collar = Palette.Cream,
			tie = Palette.Navy,
		},
	},

	-- Case 1 — The Signed Lie
	june = {
		id = "june",
		name = "June Park",
		role = "Café Owner · Client",
		look = {
			skin = SKIN.Light,
			hair = HAIR.Black,
			hairStyle = "long",
			top = Palette.Cream,
			bottom = Color3.fromRGB(70, 74, 84),
		},
	},
	nadia = {
		id = "nadia",
		name = "Nadia Price",
		role = "Brightwell Sales Lead · Witness",
		look = {
			skin = SKIN.Fair,
			hair = HAIR.Auburn,
			hairStyle = "bob",
			top = Palette.Burgundy,
			bottom = Palette.Charcoal,
			collar = Palette.Ivory,
		},
	},
	kerrigan = {
		id = "kerrigan",
		name = "Dale Kerrigan",
		role = "Owner, Brightwell Provisions",
		look = {
			skin = SKIN.Light,
			hair = HAIR.Grey,
			hairStyle = "short",
			top = Color3.fromRGB(84, 88, 96),
			bottom = Color3.fromRGB(84, 88, 96),
			collar = Palette.Ivory,
			tie = Palette.Sage,
		},
	},

	-- Case 2 — The Stolen Spark
	kai = {
		id = "kai",
		name = "Kai Mercer",
		role = "Inventor · Client",
		look = {
			skin = SKIN.Brown,
			hair = HAIR.Black,
			hairStyle = "short",
			top = Palette.Sage,
			bottom = Color3.fromRGB(58, 62, 70),
		},
	},
	lusk = {
		id = "lusk",
		name = "Gregory Lusk",
		role = "Lead Engineer, Haldane · Witness",
		look = {
			skin = SKIN.Fair,
			hair = HAIR.Dark,
			hairStyle = "short",
			top = Color3.fromRGB(70, 92, 120),
			bottom = Palette.Charcoal,
			collar = Palette.Ivory,
		},
	},

	-- Case 3 — The Midnight File
	nora = {
		id = "nora",
		name = "Nora Lindqvist",
		role = "Systems Analyst · Client",
		look = {
			skin = SKIN.Fair,
			hair = HAIR.Blonde,
			hairStyle = "long",
			top = Palette.NavySoft,
			bottom = Palette.Charcoal,
			collar = Palette.Cream,
		},
	},
	cole = {
		id = "cole",
		name = "Martin Cole",
		role = "Head of Security, Crestline · Witness",
		look = {
			skin = SKIN.Tan,
			hair = HAIR.Grey,
			hairStyle = "crop",
			top = Color3.fromRGB(30, 30, 34),
			bottom = Color3.fromRGB(30, 30, 34),
			collar = Palette.Ivory,
			tie = Color3.fromRGB(30, 30, 34),
		},
	},
	rosa = {
		id = "rosa",
		name = "Rosa Delgado",
		role = "Night Facilities Crew · Witness",
		look = {
			skin = SKIN.Tan,
			hair = HAIR.Dark,
			hairStyle = "bun",
			top = Color3.fromRGB(64, 96, 104),
			bottom = Color3.fromRGB(48, 52, 58),
		},
	},
}

return Characters
