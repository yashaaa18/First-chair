--[[
	CaseCatalog — public, non-secret case metadata for menus.
	Answer keys live only on the server (ServerScriptService.Server.Cases).
]]

local CaseCatalog = {
	order = { "case1", "case2", "case3" },
	cases = {
		case1 = {
			id = "case1",
			number = 1,
			title = "The Signed Lie",
			client = "June Park",
			blurb = "A café owner is sued over a contract she swears she never signed.",
			minutes = "5–8 min",
		},
		case2 = {
			id = "case2",
			number = 2,
			title = "The Stolen Spark",
			client = "Kai Mercer",
			blurb = "A young inventor is accused of copying a rival's design.",
			minutes = "6–10 min",
		},
		case3 = {
			id = "case3",
			number = 3,
			title = "The Midnight File",
			client = "Nora Lindqvist",
			blurb = "A secret file vanishes during a blackout. One employee takes the blame.",
			minutes = "8–10 min",
		},
	},
}

function CaseCatalog.get(id: string)
	return CaseCatalog.cases[id]
end

function CaseCatalog.indexOf(id: string): number?
	return table.find(CaseCatalog.order, id)
end

return CaseCatalog
