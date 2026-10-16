--[[
	Theme — typography, colours and sizes for the interface.
	Reference canvas is 960 × 560; Root scales it to fit any phone, tablet or monitor.
]]

local Palette = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Palette)

local Theme = {}

Theme.Palette = Palette

Theme.Fonts = {
	Display = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold),
	Serif = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Regular),
	SerifItalic = Font.new(
		"rbxasset://fonts/families/Merriweather.json",
		Enum.FontWeight.Regular,
		Enum.FontStyle.Italic
	),
	Body = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium),
	BodyBold = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold),
	Label = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold),
	Mono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular),
}

Theme.Colors = {
	Panel = Palette.NavyDeep,
	PanelSoft = Palette.Navy,
	Paper = Palette.Ivory,
	PaperDim = Palette.Cream,
	Ink = Palette.Espresso,
	InkSoft = Color3.fromRGB(96, 80, 68),
	Text = Palette.Ivory,
	TextDim = Color3.fromRGB(196, 188, 172),
	Accent = Palette.Gold,
	AccentDeep = Palette.Brass,
	Success = Palette.Success,
	Danger = Palette.Danger,
	Scrim = Color3.fromRGB(6, 9, 15),
}

Theme.Text = {
	Hero = 64,
	Title = 30,
	Heading = 22,
	Body = 19,
	Small = 15,
	Tiny = 12,
}

Theme.Radius = UDim.new(0, 10)
Theme.RadiusSmall = UDim.new(0, 6)
Theme.PanelTransparency = 0.06
Theme.TouchHeight = 54 -- minimum button height on the reference canvas

Theme.Reference = Vector2.new(960, 560)

return Theme
