--[[
	Evidence — everything to do with exhibits:
	  Evidence.review(defs)                 inspect every item, then continue
	  Evidence.pick(inventory, opts)        choose 1 (present) or 2 (combine) items
	  Evidence.inspect(def, actions?)       full-screen exhibit view
	  Evidence.caseFile(inventory)          browse everything you hold
	Each exhibit gets a small illustration drawn in UI (no image assets needed).
]]

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)

local Evidence = {}

local C = Theme.Colors
local P = Theme.Palette

export type Def = {
	id: string,
	name: string,
	kind: string,
	summary: string,
	details: { string },
	keyDetail: string?,
}

local KIND_LABEL = {
	document = "DOCUMENT",
	photo = "FOOTAGE",
	data = "DIGITAL RECORD",
	statement = "STATEMENT",
	combined = "COMBINED EVIDENCE",
}

local sounds: { page: () -> (), confirm: () -> () } = {
	page = function() end,
	confirm = function() end,
}
function Evidence.setSounds(page: () -> (), confirm: () -> ())
	sounds.page = page
	sounds.confirm = confirm
end

----------------------------------------------------------------- illustrations
local function bar(
	parent: Instance,
	x: number,
	y: number,
	w: number,
	h: number,
	color: Color3,
	transparency: number?
)
	return Kit.new("Frame", {
		BackgroundColor3 = color,
		BackgroundTransparency = transparency or 0,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(w, h),
		Parent = parent,
	})
end

-- Draws a little exhibit illustration filling `parent`.
function Evidence.art(kind: string, parent: GuiObject)
	if kind == "photo" then
		local screen = bar(parent, 0.06, 0.08, 0.88, 0.84, P.Charcoal)
		Kit.corner(UDim.new(0, 4)).Parent = screen
		local g = bar(screen, 0, 0.55, 1, 0.45, P.NavySoft, 0.3)
		g.ZIndex = screen.ZIndex
		bar(screen, 0.12, 0.3, 0.18, 0.45, P.Walnut) -- a doorway
		bar(screen, 0.55, 0.42, 0.3, 0.16, P.Stone, 0.4) -- counter
		local dot = bar(screen, 0.07, 0.08, 0.06, 0.08, P.Danger)
		Kit.corner(UDim.new(1, 0)).Parent = dot
		Kit.text({
			Text = "REC",
			FontFace = Theme.Fonts.Mono,
			TextSize = 10,
			TextColor3 = P.Ivory,
			Position = UDim2.fromScale(0.15, 0.04),
			Size = UDim2.fromScale(0.4, 0.16),
			Parent = screen,
		})
		Kit.text({
			Text = "18:00:00",
			FontFace = Theme.Fonts.Mono,
			TextSize = 10,
			TextColor3 = P.Ivory,
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.fromScale(0.45, 0.82),
			Size = UDim2.fromScale(0.5, 0.14),
			Parent = screen,
		})
	elseif kind == "data" then
		local screen = bar(parent, 0.06, 0.08, 0.88, 0.84, P.NavyDeep)
		Kit.corner(UDim.new(0, 4)).Parent = screen
		Kit.stroke(P.NavySoft, 1, 0).Parent = screen
		for i = 0, 4 do
			local w = ({ 0.7, 0.5, 0.62, 0.38, 0.55 })[i + 1]
			bar(screen, 0.1, 0.16 + i * 0.15, w, 0.06, if i == 2 then P.Gold else P.NavySoft)
		end
		bar(screen, 0.1, 0.16 + 5 * 0.15, 0.06, 0.08, P.Gold)
	elseif kind == "statement" then
		local paper = bar(parent, 0.14, 0.06, 0.72, 0.88, P.Ivory)
		Kit.corner(UDim.new(0, 3)).Parent = paper
		Kit.text({
			Text = "“",
			FontFace = Theme.Fonts.Display,
			TextSize = 46,
			TextColor3 = P.Brass,
			Position = UDim2.fromScale(0.08, -0.02),
			Size = UDim2.fromScale(0.5, 0.4),
			Parent = paper,
		})
		for i = 0, 3 do
			bar(paper, 0.14, 0.42 + i * 0.12, if i == 3 then 0.45 else 0.72, 0.04, P.Stone)
		end
	elseif kind == "combined" then
		local back = bar(parent, 0.1, 0.06, 0.56, 0.74, P.Cream)
		back.Rotation = -8
		Kit.corner(UDim.new(0, 3)).Parent = back
		local front = bar(parent, 0.34, 0.2, 0.56, 0.74, P.Ivory)
		front.Rotation = 6
		Kit.corner(UDim.new(0, 3)).Parent = front
		for i = 0, 2 do
			bar(front, 0.14, 0.2 + i * 0.16, 0.7, 0.05, P.Stone)
		end
		local link = bar(parent, 0.38, 0.36, 0.24, 0.24, P.Brass)
		link.SizeConstraint = Enum.SizeConstraint.RelativeYY
		Kit.corner(UDim.new(1, 0)).Parent = link
		Kit.text({
			Text = "+",
			FontFace = Theme.Fonts.BodyBold,
			TextSize = 20,
			TextColor3 = P.NavyDeep,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			Parent = link,
		})
	else -- document
		local paper = bar(parent, 0.16, 0.06, 0.68, 0.88, P.Ivory)
		Kit.corner(UDim.new(0, 3)).Parent = paper
		bar(paper, 0.14, 0.1, 0.5, 0.07, P.Navy)
		for i = 0, 3 do
			bar(paper, 0.14, 0.26 + i * 0.1, 0.72, 0.035, P.Stone)
		end
		bar(paper, 0.14, 0.78, 0.36, 0.025, P.Espresso)
		local seal = bar(paper, 0.62, 0.66, 0.24, 0.2, P.Burgundy)
		seal.SizeConstraint = Enum.SizeConstraint.RelativeXX
		Kit.corner(UDim.new(1, 0)).Parent = seal
	end
end

----------------------------------------------------------------- card
local CARD_SIZE = Vector2.new(168, 196)

local function makeCard(def: Def, parent: Instance, order: number): (TextButton, Frame)
	local card = Kit.new("TextButton", {
		Name = def.id,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = P.Navy,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y),
		LayoutOrder = order,
		Parent = parent,
	})
	Kit.corner().Parent = card
	local stroke = Kit.stroke(C.AccentDeep, 1, 0.55)
	stroke.Parent = card
	local artBox = Kit.new("Frame", {
		BackgroundColor3 = P.NavyDeep,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 0, 108),
		Parent = card,
	})
	Kit.corner(Theme.RadiusSmall).Parent = artBox
	Evidence.art(def.kind, artBox)
	Kit.text({
		Text = KIND_LABEL[def.kind] or "EVIDENCE",
		FontFace = Theme.Fonts.Label,
		TextSize = Theme.Text.Tiny - 1,
		TextColor3 = C.Accent,
		Position = UDim2.fromOffset(12, 124),
		Size = UDim2.new(1, -24, 0, 14),
		Parent = card,
	})
	Kit.text({
		Text = def.name,
		FontFace = Theme.Fonts.Display,
		TextSize = Theme.Text.Small,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(12, 140),
		Size = UDim2.new(1, -24, 0, 44),
		Parent = card,
	})
	local scale = Kit.new("UIScale", { Parent = card })
	card.MouseButton1Down:Connect(function()
		Kit.tween(scale, 0.08, { Scale = 0.97 })
	end)
	card.MouseButton1Up:Connect(function()
		Kit.tween(scale, 0.12, { Scale = 1 })
	end)
	card.MouseLeave:Connect(function()
		Kit.tween(scale, 0.12, { Scale = 1 })
	end)
	return card, artBox
end

local function setSelected(card: TextButton, selected: boolean)
	local stroke = card:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = if selected then C.Accent else C.AccentDeep
		stroke.Thickness = if selected then 3 else 1
		stroke.Transparency = if selected then 0 else 0.55
	end
	card.BackgroundColor3 = if selected then P.NavySoft else P.Navy
end

local function badge(card: Instance, text: string, color: Color3): Frame
	local b = Kit.new("Frame", {
		Name = "Badge",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.fromOffset(28, 28),
		ZIndex = 5,
		Parent = card,
	})
	Kit.corner(UDim.new(1, 0)).Parent = b
	Kit.text({
		Text = text,
		FontFace = Theme.Fonts.BodyBold,
		TextSize = Theme.Text.Small,
		TextColor3 = P.NavyDeep,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 6,
		Parent = b,
	})
	return b
end

-- Small "i" button to read an exhibit without selecting it.
local function infoButton(card: Instance, onClick: () -> ())
	local b = Kit.new("TextButton", {
		Name = "Info",
		Text = "i",
		FontFace = Theme.Fonts.Display,
		TextSize = Theme.Text.Small,
		TextColor3 = P.NavyDeep,
		AutoButtonColor = true,
		BackgroundColor3 = P.Ivory,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.fromOffset(30, 30),
		ZIndex = 5,
		Parent = card,
	})
	Kit.corner(UDim.new(1, 0)).Parent = b
	b.Activated:Connect(onClick)
end

----------------------------------------------------------------- modal frame
local function modalShell(
	title: string,
	subtitle: string?,
	parent: Instance?
): (Frame, Frame, Frame, TextButton)
	local layer = Kit.new("Frame", {
		Name = "EvidenceModal",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent or Root.modal,
	})
	local scrim = Kit.scrim(layer, 1)
	Kit.tween(scrim, 0.25, { BackgroundTransparency = 0.35 })
	local card = Kit.panel({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 16),
		Size = UDim2.new(1, -60, 1, -70),
		Parent = layer,
	})
	Kit.new("UISizeConstraint", { MaxSize = Vector2.new(920, 520), Parent = card })
	Kit.padding(18, 22).Parent = card
	Kit.tween(card, 0.25, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Enum.EasingStyle.Quart)

	Kit.text({
		Text = title,
		FontFace = Theme.Fonts.Display,
		TextSize = Theme.Text.Heading,
		Size = UDim2.new(1, -10, 0, 30),
		Parent = card,
	})
	Kit.text({
		Text = subtitle or "",
		FontFace = Theme.Fonts.Body,
		TextSize = Theme.Text.Small,
		TextColor3 = C.TextDim,
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, -10, 0, 22),
		Parent = card,
	})
	local grid = Kit.new("ScrollingFrame", {
		Name = "Grid",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 64),
		Size = UDim2.new(1, 0, 1, -64 - 66),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.AccentDeep,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = card,
	})
	Kit.padding(6).Parent = grid
	Kit.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y),
		CellPadding = UDim2.fromOffset(14, 14),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	local footer = Kit.new("Frame", {
		Name = "Footer",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 56),
		Parent = card,
	})
	Kit.list(Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center).Parent =
		footer
	return layer, grid, footer, scrim
end

----------------------------------------------------------------- inspector
--[[
	Show one exhibit in full. `actions` adds extra buttons (e.g. "Present").
	Yields until closed; returns the chosen action id or "close".
]]
function Evidence.inspect(def: Def, actions: { { id: string, text: string } }?): string
	sounds.page()
	return Kit.await(function(resolve)
		local layer = Kit.new("Frame", {
			Name = "Inspector",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = Root.popup,
		})
		local scrim = Kit.scrim(layer, 1)
		Kit.tween(scrim, 0.2, { BackgroundTransparency = 0.3 })
		local card = Kit.panel({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 18),
			Size = UDim2.new(1, -60, 1, -60),
			Parent = layer,
		})
		Kit.new("UISizeConstraint", { MaxSize = Vector2.new(860, 480), Parent = card })
		Kit.padding(20, 24).Parent = card
		Kit.tween(card, 0.25, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Enum.EasingStyle.Quart)

		-- left: the illustration on a paper-toned plate
		local plate = Kit.new("Frame", {
			BackgroundColor3 = P.NavyDeep,
			BorderSizePixel = 0,
			Size = UDim2.new(0.36, 0, 1, -66),
			Parent = card,
		})
		Kit.corner().Parent = plate
		Kit.stroke(C.AccentDeep, 1, 0.6).Parent = plate
		local artArea = Kit.new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.86, 0.7),
			Parent = plate,
		})
		Evidence.art(def.kind, artArea)

		-- right: words
		local right = Kit.new("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0.36, 22, 0, 0),
			Size = UDim2.new(0.64, -22, 1, -66),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = C.AccentDeep,
			Parent = card,
		})
		Kit.list(Enum.FillDirection.Vertical, 8).Parent = right
		Kit.text({
			Text = KIND_LABEL[def.kind] or "EVIDENCE",
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Tiny,
			TextColor3 = C.Accent,
			Size = UDim2.new(1, -8, 0, 16),
			LayoutOrder = 1,
			Parent = right,
		})
		Kit.text({
			Text = def.name,
			FontFace = Theme.Fonts.Display,
			TextSize = Theme.Text.Title - 4,
			Size = UDim2.new(1, -8, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			Parent = right,
		})
		Kit.text({
			Text = def.summary,
			FontFace = Theme.Fonts.SerifItalic,
			TextSize = Theme.Text.Small,
			TextColor3 = C.TextDim,
			Size = UDim2.new(1, -8, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 3,
			Parent = right,
		})
		for i, line in def.details do
			local row = Kit.new("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -8, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 10 + i,
				Parent = right,
			})
			Kit.new("Frame", {
				BackgroundColor3 = C.AccentDeep,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(2, 9),
				Size = UDim2.fromOffset(6, 6),
				Parent = row,
			})
			Kit.text({
				Text = line,
				FontFace = Theme.Fonts.Body,
				TextSize = Theme.Text.Small + 1,
				Position = UDim2.fromOffset(18, 0),
				Size = UDim2.new(1, -18, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = row,
			})
		end
		if def.keyDetail then
			local key = Kit.new("Frame", {
				BackgroundColor3 = P.Brass,
				BackgroundTransparency = 0.82,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -8, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 50,
				Parent = right,
			})
			Kit.corner(Theme.RadiusSmall).Parent = key
			Kit.stroke(C.Accent, 1, 0.3).Parent = key
			Kit.padding(10, 14).Parent = key
			Kit.list(Enum.FillDirection.Vertical, 4).Parent = key
			Kit.text({
				Text = "KEY DETAIL",
				FontFace = Theme.Fonts.Label,
				TextSize = Theme.Text.Tiny,
				TextColor3 = C.Accent,
				Size = UDim2.new(1, 0, 0, 14),
				LayoutOrder = 1,
				Parent = key,
			})
			Kit.text({
				Text = def.keyDetail,
				FontFace = Theme.Fonts.BodyBold,
				TextSize = Theme.Text.Small + 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2,
				Parent = key,
			})
		end

		local footer = Kit.new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 54),
			Parent = card,
		})
		Kit.list(
			Enum.FillDirection.Horizontal,
			12,
			Enum.HorizontalAlignment.Right,
			Enum.VerticalAlignment.Center
		).Parent =
			footer

		local function close(result: string)
			Kit.tween(scrim, 0.15, { BackgroundTransparency = 1 })
			local t =
				Kit.tween(card, 0.15, { Position = UDim2.new(0.5, 0, 0.5, 18), BackgroundTransparency = 1 })
			t.Completed:Connect(function()
				layer:Destroy()
				resolve(result)
			end)
		end
		Kit.button({
			text = "Close",
			style = "secondary",
			size = UDim2.fromOffset(150, Theme.TouchHeight),
			layoutOrder = 1,
			parent = footer,
			onClick = function()
				close("close")
			end,
		})
		local extra: { { id: string, text: string } } = actions or {}
		for i, action in extra do
			Kit.button({
				text = action.text,
				style = "primary",
				size = UDim2.fromOffset(190, Theme.TouchHeight),
				layoutOrder = 1 + i,
				parent = footer,
				onClick = function()
					close(action.id)
				end,
			})
		end
		return nil
	end)
end

----------------------------------------------------------------- review
-- Show items; the player must open each one before continuing.
function Evidence.review(defs: { Def }, prompt: string?)
	return Kit.await(function(resolve)
		local layer, grid, footer = modalShell("Evidence Review", prompt or "Tap each item to inspect it.")
		local opened: { [string]: boolean } = {}
		local count = 0
		local continueButton: TextButton
		local progress = Kit.text({
			Text = "",
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Small,
			TextColor3 = C.TextDim,
			TextXAlignment = Enum.TextXAlignment.Right,
			Size = UDim2.fromOffset(200, Theme.TouchHeight),
			LayoutOrder = 0,
			Parent = footer,
		})
		local function refresh()
			progress.Text = ("%d of %d inspected"):format(count, #defs)
			Kit.setEnabled(continueButton, count >= #defs)
		end
		continueButton = Kit.button({
			text = "Continue",
			style = "primary",
			size = UDim2.fromOffset(180, Theme.TouchHeight),
			layoutOrder = 1,
			parent = footer,
			onClick = function()
				if count >= #defs then
					sounds.confirm()
					layer:Destroy()
					resolve()
				end
			end,
		})
		for i, def in defs do
			local card = makeCard(def, grid, i)
			local hint = badge(card, "?", P.Ivory)
			card.Activated:Connect(function()
				Evidence.inspect(def)
				if not opened[def.id] then
					opened[def.id] = true
					count += 1
					hint:Destroy()
					badge(card, "✓", P.Success)
					refresh()
				end
			end)
		end
		refresh()
		return nil
	end)
end

----------------------------------------------------------------- picker
export type PickOptions = {
	title: string,
	prompt: string?,
	count: number, -- 1 to present, 2 to combine
	confirmText: string,
	cancellable: boolean?,
}

-- Returns a list of chosen ids, or nil if cancelled.
function Evidence.pick(inventory: { Def }, opts: PickOptions): { string }?
	return Kit.await(function(resolve)
		local layer, grid, footer = modalShell(opts.title, opts.prompt)
		local selected: { string } = {}
		local cards: { [string]: TextButton } = {}
		local confirm: TextButton

		local function refresh()
			for id, card in cards do
				local index = table.find(selected, id)
				setSelected(card, index ~= nil)
				local existing = card:FindFirstChild("Badge")
				if existing then
					existing:Destroy()
				end
				if index and opts.count > 1 then
					badge(card, tostring(index), P.Gold)
				end
			end
			Kit.setEnabled(confirm, #selected == opts.count)
		end

		if opts.cancellable then
			Kit.button({
				text = "Back",
				style = "secondary",
				size = UDim2.fromOffset(140, Theme.TouchHeight),
				layoutOrder = 1,
				parent = footer,
				onClick = function()
					layer:Destroy()
					resolve(nil)
				end,
			})
		end
		confirm = Kit.button({
			text = opts.confirmText,
			style = "primary",
			size = UDim2.fromOffset(200, Theme.TouchHeight),
			layoutOrder = 2,
			parent = footer,
			onClick = function()
				if #selected == opts.count then
					layer:Destroy()
					resolve(table.clone(selected))
				end
			end,
		})

		for i, def in inventory do
			local card = makeCard(def, grid, i)
			cards[def.id] = card
			infoButton(card, function()
				Evidence.inspect(def)
			end)
			card.Activated:Connect(function()
				sounds.page()
				local index = table.find(selected, def.id)
				if index then
					table.remove(selected, index)
				elseif opts.count == 1 then
					selected = { def.id }
				elseif #selected < opts.count then
					table.insert(selected, def.id)
				else
					table.remove(selected, 1)
					table.insert(selected, def.id)
				end
				refresh()
			end)
		end
		refresh()
		return nil
	end)
end

----------------------------------------------------------------- order (Case 3)
-- Tap exhibits in sequence. Returns ordered ids.
function Evidence.order(items: { Def }, prompt: string): { string }
	return Kit.await(function(resolve)
		local layer, grid, footer = modalShell("Present in Order", prompt)
		local sequence: { string } = {}
		local cards: { [string]: TextButton } = {}
		local submit: TextButton

		local strip = Kit.text({
			Text = "",
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Small,
			TextColor3 = C.Accent,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(0, 360, 0, Theme.TouchHeight),
			LayoutOrder = 0,
			Parent = footer,
		})

		local function refresh()
			for id, card in cards do
				local index = table.find(sequence, id)
				setSelected(card, index ~= nil)
				local existing = card:FindFirstChild("Badge")
				if existing then
					existing:Destroy()
				end
				if index then
					badge(card, tostring(index), P.Gold)
				end
			end
			strip.Text = ("%d of %d placed — tap a card again to remove it"):format(#sequence, #items)
			Kit.setEnabled(submit, #sequence == #items)
		end

		Kit.button({
			text = "Reset",
			style = "secondary",
			size = UDim2.fromOffset(120, Theme.TouchHeight),
			layoutOrder = 1,
			parent = footer,
			onClick = function()
				table.clear(sequence)
				refresh()
			end,
		})
		submit = Kit.button({
			text = "Present",
			style = "primary",
			size = UDim2.fromOffset(170, Theme.TouchHeight),
			layoutOrder = 2,
			parent = footer,
			onClick = function()
				if #sequence == #items then
					layer:Destroy()
					resolve(table.clone(sequence))
				end
			end,
		})

		for i, def in items do
			local card = makeCard(def, grid, i)
			cards[def.id] = card
			infoButton(card, function()
				Evidence.inspect(def)
			end)
			card.Activated:Connect(function()
				sounds.page()
				local index = table.find(sequence, def.id)
				if index then
					-- remove this card and everything placed after it
					for j = #sequence, index, -1 do
						table.remove(sequence, j)
					end
				else
					table.insert(sequence, def.id)
				end
				refresh()
			end)
		end
		refresh()
		return nil
	end)
end

----------------------------------------------------------------- case file
-- Read-only browser of everything the player holds. Opens above the current step.
function Evidence.caseFile(inventory: { Def })
	return Kit.await(function(resolve)
		local layer, grid, footer = modalShell(
			"Case File",
			if #inventory == 0 then "No evidence yet." else "Tap an item to read it.",
			Root.popup
		)
		Kit.button({
			text = "Close",
			style = "secondary",
			size = UDim2.fromOffset(160, Theme.TouchHeight),
			parent = footer,
			onClick = function()
				layer:Destroy()
				resolve()
			end,
		})
		for i, def in inventory do
			local card = makeCard(def, grid, i)
			card.Activated:Connect(function()
				Evidence.inspect(def)
			end)
		end
		return nil
	end)
end

return Evidence
