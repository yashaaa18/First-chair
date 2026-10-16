--[[
	Feedback — every "you did something" moment: toasts, the objection stamp,
	new-evidence cards and the verdict banner.
]]

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)

local Feedback = {}

local C = Theme.Colors
local toastQueue = 0

export type ToastKind = "success" | "danger" | "info" | "warning"

function Feedback.toast(text: string, kind: ToastKind?, duration: number?)
	local accent = C.Accent
	if kind == "success" then
		accent = C.Success
	elseif kind == "danger" then
		accent = C.Danger
	elseif kind == "warning" then
		accent = Color3.fromRGB(214, 160, 90)
	end
	toastQueue += 1
	local offset = 72 + ((toastQueue - 1) % 3) * 58
	local toast = Kit.panel({
		Name = "Toast",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, offset - 12),
		Size = UDim2.new(0, 0, 0, 46),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = Root.toast,
	})
	local stroke = toast:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Color = accent
	stroke.Transparency = 1
	Kit.padding(0, 18, 0, 18).Parent = toast
	local bar = Kit.new("Frame", {
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 0, 22),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundTransparency = 1,
		Parent = toast,
	})
	Kit.corner(UDim.new(0, 2)).Parent = bar
	local label = Kit.text({
		Text = text,
		FontFace = Theme.Fonts.Label,
		TextSize = Theme.Text.Small + 1,
		TextTransparency = 1,
		TextWrapped = false,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		Parent = toast,
	})
	Kit.new("UISizeConstraint", { MaxSize = Vector2.new(720, 46), Parent = toast })
	Kit.tween(
		toast,
		0.25,
		{ Position = UDim2.new(0.5, 0, 0, offset), BackgroundTransparency = Theme.PanelTransparency }
	)
	Kit.tween(stroke, 0.25, { Transparency = 0.3 })
	Kit.tween(bar, 0.25, { BackgroundTransparency = 0 })
	Kit.tween(label, 0.25, { TextTransparency = 0 })
	task.delay(duration or 2.4, function()
		Kit.tween(toast, 0.3, { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, offset - 8) })
		Kit.tween(stroke, 0.3, { Transparency = 1 })
		Kit.tween(bar, 0.3, { BackgroundTransparency = 1 })
		local t = Kit.tween(label, 0.3, { TextTransparency = 1 })
		t.Completed:Wait()
		toast:Destroy()
		toastQueue = math.max(0, toastQueue - 1)
	end)
end

-- Big brass stamp across the screen. Yields ~1.3s.
function Feedback.objection(word: string?, sub: string?)
	local layer = Kit.new("Frame", {
		Name = "Objection",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 40,
		Parent = Root.overlay,
	})
	local flash = Kit.new("Frame", {
		BackgroundColor3 = C.Paper,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 40,
		Parent = layer,
	})
	local band = Kit.new("Frame", {
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1.4, 0, 0, 0),
		Rotation = -4,
		ZIndex = 41,
		Parent = layer,
	})
	for _, y in { 0, 1 } do
		Kit.new("Frame", {
			BackgroundColor3 = C.Accent,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, y),
			Position = UDim2.fromScale(0, y),
			Size = UDim2.new(1, 0, 0, 3),
			ZIndex = 42,
			Parent = band,
		})
	end
	local word_ = Kit.text({
		Text = word or "OBJECTION!",
		FontFace = Theme.Fonts.Display,
		TextSize = 84,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, if sub then -12 else 0),
		Size = UDim2.new(1, 0, 0, 100),
		Rotation = -4,
		ZIndex = 43,
		Parent = layer,
	})
	Kit.new("UIStroke", { Color = C.Scrim, Thickness = 3, Parent = word_ })
	local scale = Kit.new("UIScale", { Scale = 2.2, Parent = word_ })
	local subLabel = sub
		and Kit.text({
			Text = sub,
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Body,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 52),
			Size = UDim2.new(1, 0, 0, 30),
			Rotation = -4,
			TextTransparency = 1,
			ZIndex = 43,
			Parent = layer,
		})

	Kit.tween(flash, 0.35, { BackgroundTransparency = 1 })
	Kit.tween(band, 0.22, { Size = UDim2.new(1.4, 0, 0, 170) }, Enum.EasingStyle.Back)
	Kit.tween(scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
	if subLabel then
		Kit.tween(subLabel, 0.3, { TextTransparency = 0 })
	end
	task.wait(1.15)
	Kit.tween(band, 0.25, { BackgroundTransparency = 1 })
	Kit.tween(word_, 0.25, { TextTransparency = 1 })
	if subLabel then
		Kit.tween(subLabel, 0.25, { TextTransparency = 1 })
	end
	for _, d in band:GetChildren() do
		if d:IsA("Frame") then
			Kit.tween(d, 0.25, { BackgroundTransparency = 1 })
		end
	end
	local stroke = word_:FindFirstChildOfClass("UIStroke")
	if stroke then
		Kit.tween(stroke, 0.25, { Transparency = 1 })
	end
	task.wait(0.27)
	layer:Destroy()
end

-- "Added to case file" card sliding in from the right. Non-blocking.
function Feedback.evidenceGained(name: string, label: string?)
	local card = Kit.panel({
		Name = "Gained",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 300, 0, 72),
		Size = UDim2.new(0, 280, 0, 64),
		Parent = Root.toast,
	})
	Kit.padding(10, 14).Parent = card
	Kit.text({
		Text = label or "ADDED TO CASE FILE",
		FontFace = Theme.Fonts.Label,
		TextSize = Theme.Text.Tiny,
		TextColor3 = C.Accent,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = card,
	})
	Kit.text({
		Text = name,
		FontFace = Theme.Fonts.Display,
		TextSize = Theme.Text.Body,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 26),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})
	Kit.tween(card, 0.35, { Position = UDim2.new(1, -16, 0, 72) }, Enum.EasingStyle.Back)
	task.delay(2.4, function()
		local t = Kit.tween(
			card,
			0.3,
			{ Position = UDim2.new(1, 300, 0, 72) },
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		)
		t.Completed:Wait()
		card:Destroy()
	end)
end

-- Full-screen verdict. Yields until the player taps.
function Feedback.verdict(title: string, subtitle: string?, onShow: (() -> ())?)
	return Kit.await(function(resolve)
		local layer = Kit.new("TextButton", {
			Name = "Verdict",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = C.Scrim,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 30,
			Parent = Root.overlay,
		})
		local eyebrow = Kit.text({
			Text = "THE COURT RULES",
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Small,
			TextColor3 = C.Accent,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, -78),
			TextTransparency = 1,
			ZIndex = 31,
			Parent = layer,
		})
		local rules = {}
		for _, y in { -52, 62 } do
			table.insert(
				rules,
				Kit.new("Frame", {
					BackgroundColor3 = C.Accent,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, y),
					Size = UDim2.new(0, 0, 0, 1),
					ZIndex = 31,
					Parent = layer,
				})
			)
		end
		local big = Kit.text({
			Text = title,
			FontFace = Theme.Fonts.Display,
			TextSize = 52,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -60, 0, 70),
			TextTransparency = 1,
			ZIndex = 31,
			Parent = layer,
		})
		local small = Kit.text({
			Text = subtitle or "",
			FontFace = Theme.Fonts.SerifItalic,
			TextSize = Theme.Text.Body,
			TextColor3 = C.TextDim,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 40),
			Size = UDim2.new(1, -60, 0, 30),
			TextTransparency = 1,
			ZIndex = 31,
			Parent = layer,
		})
		local hint = Kit.text({
			Text = "TAP TO CONTINUE",
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Tiny,
			TextColor3 = C.TextDim,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -30),
			TextTransparency = 1,
			ZIndex = 31,
			Parent = layer,
		})

		Kit.tween(layer, 0.5, { BackgroundTransparency = 0.2 })
		if onShow then
			task.delay(0.35, onShow)
		end
		task.delay(0.3, function()
			Kit.tween(eyebrow, 0.4, { TextTransparency = 0 })
			for _, r in rules do
				Kit.tween(r, 0.7, { Size = UDim2.new(0, 420, 0, 1) }, Enum.EasingStyle.Quart)
			end
			local s = Kit.new("UIScale", { Scale = 1.25, Parent = big })
			Kit.tween(s, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
			Kit.tween(big, 0.4, { TextTransparency = 0 })
			task.wait(0.35)
			Kit.tween(small, 0.4, { TextTransparency = 0 })
			task.wait(0.6)
			Kit.tween(hint, 0.4, { TextTransparency = 0.2 })
		end)

		local ready = false
		task.delay(1.2, function()
			ready = true
		end)
		layer.Activated:Connect(function()
			if not ready then
				return
			end
			ready = false
			local t = Kit.tween(layer, 0.35, { BackgroundTransparency = 1 })
			for _, label in { eyebrow, big, small, hint } do
				Kit.tween(label, 0.3, { TextTransparency = 1 })
			end
			for _, r in rules do
				Kit.tween(r, 0.3, { BackgroundTransparency = 1 })
			end
			t.Completed:Connect(function()
				layer:Destroy()
				resolve()
			end)
		end)
		return nil
	end)
end

return Feedback
