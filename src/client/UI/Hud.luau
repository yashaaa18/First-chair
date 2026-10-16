--[[
	Hud — the in-case heads-up display: case title + current objective (top
	centre) and the Case File / Pause buttons (top right).
]]

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)

local Hud = {}

local C = Theme.Colors

local frame: Frame? = nil
local objectiveLabel: TextLabel? = nil
local fileButton: TextButton? = nil
local objectivePanel: Frame? = nil

export type Callbacks = { onCaseFile: () -> (), onPause: () -> () }

function Hud.show(caseTitle: string, callbacks: Callbacks)
	Hud.hide()
	local root = Kit.new("Frame", {
		Name = "Hud",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = Root.hud,
	})
	frame = root

	local panel = Kit.panel({
		Name = "Objective",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -70),
		Size = UDim2.fromOffset(0, 54),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = root,
	})
	objectivePanel = panel
	Kit.new(
		"UISizeConstraint",
		{ MinSize = Vector2.new(300, 54), MaxSize = Vector2.new(560, 54), Parent = panel }
	)
	Kit.padding(7, 20).Parent = panel
	Kit.list(Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Center).Parent = panel
	Kit.text({
		Text = string.upper(caseTitle),
		FontFace = Theme.Fonts.Label,
		TextSize = Theme.Text.Tiny,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = false,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 15),
		LayoutOrder = 1,
		Parent = panel,
	})
	objectiveLabel = Kit.text({
		Text = "",
		FontFace = Theme.Fonts.BodyBold,
		TextSize = Theme.Text.Small + 1,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 22),
		LayoutOrder = 2,
		Parent = panel,
	})
	Kit.tween(panel, 0.4, { Position = UDim2.new(0.5, 0, 0, 12) }, Enum.EasingStyle.Quart)

	local buttons = Kit.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 12),
		Size = UDim2.fromOffset(260, 50),
		Parent = root,
	})
	Kit.list(Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Right).Parent = buttons
	fileButton = Kit.button({
		text = "Case File",
		style = "secondary",
		textSize = Theme.Text.Small,
		size = UDim2.fromOffset(150, 50),
		layoutOrder = 1,
		parent = buttons,
		onClick = callbacks.onCaseFile,
	})
	Kit.button({
		text = "II",
		style = "secondary",
		font = Theme.Fonts.BodyBold,
		textSize = Theme.Text.Small,
		size = UDim2.fromOffset(50, 50),
		layoutOrder = 2,
		parent = buttons,
		onClick = callbacks.onPause,
	})
end

function Hud.setObjective(text: string)
	local label = objectiveLabel
	local panel = objectivePanel
	if not label or not panel then
		return
	end
	if label.Text == text then
		return
	end
	local stroke = panel:FindFirstChildOfClass("UIStroke")
	label.TextTransparency = 1
	label.Text = text
	Kit.tween(label, 0.35, { TextTransparency = 0 })
	if stroke then
		stroke.Color = C.Accent
		stroke.Transparency = 0
		Kit.tween(stroke, 1.2, { Transparency = 0.55, Color = C.AccentDeep })
	end
end

function Hud.setEvidenceCount(n: number)
	if fileButton then
		fileButton.Text = if n > 0 then ("Case File  ·  %d"):format(n) else "Case File"
	end
end

function Hud.setVisible(visible: boolean)
	if frame then
		frame.Visible = visible
	end
end

function Hud.hide()
	if frame then
		frame:Destroy()
	end
	frame, objectiveLabel, fileButton, objectivePanel = nil, nil, nil, nil
end

return Hud
