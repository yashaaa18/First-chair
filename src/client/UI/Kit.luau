--[[
	Kit — tiny helpers for building UI in code: instance creation, tweens,
	buttons with press feedback, and a safe "await" for yielding UI flows.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local Kit = {}

local C = Theme.Colors

-- Create an instance: Kit.new("Frame", { Size = ..., Parent = ... }, { children })
function Kit.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				(inst :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function Kit.corner(radius: UDim?): UICorner
	return Kit.new("UICorner", { CornerRadius = radius or Theme.Radius })
end

function Kit.stroke(color: Color3?, thickness: number?, transparency: number?): UIStroke
	return Kit.new("UIStroke", {
		Color = color or C.AccentDeep,
		Thickness = thickness or 1,
		Transparency = transparency or 0.45,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Kit.padding(top: number, right: number?, bottom: number?, left: number?): UIPadding
	return Kit.new("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right or top),
		PaddingBottom = UDim.new(0, bottom or top),
		PaddingLeft = UDim.new(0, left or right or top),
	})
end

function Kit.list(
	direction: Enum.FillDirection?,
	padding: number?,
	halign: Enum.HorizontalAlignment?,
	valign: Enum.VerticalAlignment?
): UIListLayout
	return Kit.new("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padding or 8),
		HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = valign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

function Kit.tween(
	inst: Instance,
	time: number,
	props: { [string]: any },
	style: Enum.EasingStyle?,
	dir: Enum.EasingDirection?
): Tween
	local tween = TweenService:Create(
		inst,
		TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	tween:Play()
	return tween
end

-- A text label with sensible defaults.
function Kit.text(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		FontFace = Theme.Fonts.Body,
		TextColor3 = C.Text,
		TextSize = Theme.Text.Body,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.new(1, 0, 0, 24),
	}
	for k, v in props do
		defaults[k] = v
	end
	return Kit.new("TextLabel", defaults)
end

-- Panel: dark navy card with a fine brass edge.
function Kit.panel(props: { [string]: any }): Frame
	local defaults = {
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
	}
	for k, v in props do
		defaults[k] = v
	end
	local frame = Kit.new("Frame", defaults)
	Kit.corner().Parent = frame
	Kit.stroke(C.AccentDeep, 1, 0.55).Parent = frame
	return frame
end

-- Full-screen click-blocker behind modals.
function Kit.scrim(parent: Instance, transparency: number?): TextButton
	return Kit.new("TextButton", {
		Name = "Scrim",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = C.Scrim,
		BackgroundTransparency = transparency or 0.45,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
end

local clickSound: (() -> ())? = nil
function Kit.setClickSound(fn: () -> ())
	clickSound = fn
end

export type ButtonStyle = "primary" | "secondary" | "ghost" | "paper"

--[[
	Kit.button({ text, style, size, position, anchor, onClick, textSize, layoutOrder })
	Touch-friendly, with a gentle press animation.
]]
function Kit.button(opts: { [string]: any }): TextButton
	local style: ButtonStyle = opts.style or "primary"
	local bg, fg, strokeColor, strokeT = C.AccentDeep, C.Panel, C.Accent, 0.2
	if style == "secondary" then
		bg, fg, strokeColor, strokeT = C.PanelSoft, C.Text, C.AccentDeep, 0.35
	elseif style == "ghost" then
		bg, fg, strokeColor, strokeT = C.Panel, C.TextDim, C.AccentDeep, 0.6
	elseif style == "paper" then
		bg, fg, strokeColor, strokeT = C.Paper, C.Ink, C.AccentDeep, 0.5
	end
	local button = Kit.new("TextButton", {
		Name = opts.name or "Button",
		Text = opts.text or "",
		FontFace = opts.font or Theme.Fonts.Label,
		TextSize = opts.textSize or Theme.Text.Body,
		TextColor3 = fg,
		TextWrapped = true,
		AutoButtonColor = false,
		BackgroundColor3 = bg,
		BackgroundTransparency = if style == "ghost" then 0.35 else 0,
		BorderSizePixel = 0,
		Size = opts.size or UDim2.new(0, 220, 0, Theme.TouchHeight),
		Position = opts.position or UDim2.new(),
		AnchorPoint = opts.anchor or Vector2.zero,
		LayoutOrder = opts.layoutOrder or 0,
		TextXAlignment = opts.align or Enum.TextXAlignment.Center,
		Parent = opts.parent,
	})
	Kit.corner(Theme.RadiusSmall).Parent = button
	Kit.stroke(strokeColor, 1, strokeT).Parent = button
	local scale = Kit.new("UIScale", { Parent = button })

	local enabled = true
	button:SetAttribute("Enabled", true)
	button.MouseButton1Down:Connect(function()
		if enabled then
			Kit.tween(scale, 0.08, { Scale = 0.96 })
		end
	end)
	local function release()
		Kit.tween(scale, 0.14, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	button.MouseButton1Up:Connect(release)
	button.MouseLeave:Connect(release)
	button.Activated:Connect(function()
		if not enabled then
			return
		end
		if clickSound then
			clickSound()
		end
		if opts.onClick then
			opts.onClick()
		end
	end)
	button:GetAttributeChangedSignal("Enabled"):Connect(function()
		enabled = button:GetAttribute("Enabled") == true
		button.BackgroundTransparency = if enabled then (if style == "ghost" then 0.35 else 0) else 0.6
		button.TextTransparency = if enabled then 0 else 0.5
	end)
	return button
end

function Kit.setEnabled(button: GuiButton, enabled: boolean)
	button:SetAttribute("Enabled", enabled)
end

--[[
	Kit.await(setup) — yield the current thread until `resolve(...)` is called.
	`setup(resolve)` builds the UI and may return a cleanup function.
	Safe if the waiting thread is cancelled (e.g. quitting a case mid-step).
]]
function Kit.await(setup: ((...any) -> ()) -> (() -> ())?): ...any
	local thread = coroutine.running()
	local done = false
	local cleanup: (() -> ())? = nil
	local function resolve(...: any)
		if done then
			return
		end
		done = true
		if cleanup then
			cleanup()
			cleanup = nil
		end
		local args = table.pack(...)
		task.defer(function()
			if coroutine.status(thread) == "suspended" then
				task.spawn(thread, table.unpack(args, 1, args.n))
			end
		end)
	end
	cleanup = setup(resolve)
	if done and cleanup then
		cleanup()
		cleanup = nil
	end
	return coroutine.yield()
end

return Kit
