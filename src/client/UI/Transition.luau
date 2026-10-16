--[[
	Transition — quick fades and the elegant location title card.
]]

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)

local Transition = {}

local C = Theme.Colors
local fade: Frame? = nil

local function fader(): Frame
	if fade and fade.Parent then
		return fade
	end
	-- Full-bleed: parented to the overlay GUI itself, outside the scaled canvas.
	fade = Kit.new("Frame", {
		Name = "Fade",
		BackgroundColor3 = C.Scrim,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
		Parent = Root.overlayGui,
	})
	return fade :: Frame
end

function Transition.fadeOut(time: number?)
	local f = fader()
	f.Visible = true
	local t = Kit.tween(f, time or 0.3, { BackgroundTransparency = 0 })
	t.Completed:Wait()
end

function Transition.fadeIn(time: number?)
	local f = fader()
	local t = Kit.tween(f, time or 0.4, { BackgroundTransparency = 1 })
	t.Completed:Wait()
	f.Visible = false
end

-- "VALENCE LEGAL · NORTHBRIDGE" / "Monday · 9:02 AM" — non-blocking.
function Transition.locationCard(place: string, time: string?)
	local card = Kit.new("Frame", {
		Name = "LocationCard",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 36, 1, -210),
		Size = UDim2.new(0, 520, 0, 70),
		Parent = Root.popup,
	})
	local rule = Kit.new("Frame", {
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 0, 2),
		Position = UDim2.new(0, 0, 0, 34),
		Parent = card,
	})
	local title = Kit.text({
		Text = place,
		FontFace = Theme.Fonts.Label,
		TextSize = Theme.Text.Small,
		TextColor3 = C.Accent,
		TextTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		Parent = card,
	})
	local sub = Kit.text({
		Text = time or "",
		FontFace = Theme.Fonts.SerifItalic,
		TextSize = Theme.Text.Heading,
		TextColor3 = C.Text,
		TextTransparency = 1,
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(1, 0, 0, 30),
		Parent = card,
	})
	for _, label in { title, sub } do
		local stroke =
			Kit.new("UIStroke", { Color = C.Scrim, Thickness = 1, Transparency = 0.5, Parent = label })
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	end
	Kit.tween(rule, 0.6, { Size = UDim2.new(0, 260, 0, 2) })
	Kit.tween(title, 0.5, { TextTransparency = 0 })
	task.delay(0.15, function()
		Kit.tween(sub, 0.5, { TextTransparency = 0 })
	end)
	task.delay(2.6, function()
		if not card.Parent then
			return
		end
		Kit.tween(rule, 0.5, { BackgroundTransparency = 1 })
		Kit.tween(title, 0.5, { TextTransparency = 1 })
		local t = Kit.tween(sub, 0.5, { TextTransparency = 1 })
		t.Completed:Wait()
		card:Destroy()
	end)
end

return Transition
