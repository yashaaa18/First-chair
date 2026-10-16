--[[
	Testimony — cross-examination. Statements appear one at a time; the player
	can flip between them, PRESS for detail, or PRESENT evidence against one.

	Testimony.run(step, hooks) -> { statement, evidence }
	hooks.press(statementIndex)   plays the press conversation (yields)
	hooks.present(statementIndex) opens the evidence picker; returns id or nil
	hooks.onShow(statementIndex)  e.g. frame the witness
]]

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)

local Testimony = {}

local C = Theme.Colors

export type Hooks = {
	press: (number) -> (),
	present: (number) -> string?,
	onShow: ((number) -> ())?,
	start: number?,
}

function Testimony.run(step, hooks: Hooks): ({ statement: number, evidence: string }, number)
	return Kit.await(function(resolve)
		local statements = step.statements
		local index = math.clamp(hooks.start or 1, 1, #statements)
		local busy = false

		local layer = Kit.new("Frame", {
			Name = "Testimony",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = Root.modal,
		})

		local panel = Kit.panel({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 40),
			Size = UDim2.new(1, -48, 0, 214),
			Parent = layer,
		})
		Kit.new("UISizeConstraint", { MaxSize = Vector2.new(900, 214), Parent = panel })
		Kit.padding(14, 22).Parent = panel

		local header = Kit.text({
			Text = string.upper(step.title or "Testimony"),
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Tiny + 1,
			TextColor3 = C.Accent,
			Size = UDim2.new(1, -120, 0, 18),
			Parent = panel,
		})
		local counter = Kit.text({
			Text = "",
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Tiny + 1,
			TextColor3 = C.TextDim,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0, 120, 0, 18),
			Parent = panel,
		})
		header.Name = "Header"

		-- statement line with arrows either side
		local row = Kit.new("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 24),
			Size = UDim2.new(1, 0, 0, 96),
			Parent = panel,
		})
		local quote = Kit.text({
			Text = "",
			FontFace = Theme.Fonts.Serif,
			TextSize = Theme.Text.Body + 2,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(64, 0),
			Size = UDim2.new(1, -128, 1, 0),
			Parent = row,
		})
		local dots = Kit.new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 124),
			Size = UDim2.fromOffset(200, 8),
			Parent = panel,
		})
		Kit.list(Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Center).Parent = dots
		local dotFrames = {}
		for i = 1, #statements do
			local d = Kit.new("Frame", {
				BackgroundColor3 = C.TextDim,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(8, 8),
				LayoutOrder = i,
				Parent = dots,
			})
			Kit.corner(UDim.new(1, 0)).Parent = d
			dotFrames[i] = d
		end

		local function show(i: number, direction: number?)
			index = i
			counter.Text = ("STATEMENT %d / %d"):format(i, #statements)
			quote.Text = "“" .. statements[i].text .. "”"
			for j, d in dotFrames do
				d.BackgroundColor3 = if j == i then C.Accent else C.TextDim
				d.BackgroundTransparency = if j == i then 0 else 0.5
			end
			quote.TextTransparency = 1
			quote.Position = UDim2.fromOffset(64 + (direction or 0) * 24, 0)
			Kit.tween(quote, 0.22, { TextTransparency = 0, Position = UDim2.fromOffset(64, 0) })
			if hooks.onShow then
				task.spawn(hooks.onShow, i)
			end
		end

		local function arrow(text: string, anchorX: number, delta: number)
			Kit.button({
				text = text,
				style = "secondary",
				textSize = 26,
				size = UDim2.fromOffset(54, 72),
				anchor = Vector2.new(anchorX, 0.5),
				position = UDim2.new(anchorX, 0, 0.5, 0),
				parent = row,
				onClick = function()
					if busy then
						return
					end
					local nextIndex = ((index - 1 + delta) % #statements) + 1
					show(nextIndex, delta)
				end,
			})
		end
		arrow("‹", 0, -1)
		arrow("›", 1, 1)

		local actions = Kit.new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.new(1, 0, 0, Theme.TouchHeight),
			Parent = panel,
		})
		Kit.list(
			Enum.FillDirection.Horizontal,
			14,
			Enum.HorizontalAlignment.Center,
			Enum.VerticalAlignment.Center
		).Parent =
			actions

		local function hide(hidden: boolean)
			layer.Visible = not hidden
		end

		Kit.button({
			text = "Press",
			style = "secondary",
			size = UDim2.fromOffset(200, Theme.TouchHeight),
			layoutOrder = 1,
			parent = actions,
			onClick = function()
				if busy then
					return
				end
				busy = true
				hide(true)
				hooks.press(index)
				hide(false)
				busy = false
				show(index)
			end,
		})
		Kit.button({
			text = "Present Evidence",
			style = "primary",
			size = UDim2.fromOffset(240, Theme.TouchHeight),
			layoutOrder = 2,
			parent = actions,
			onClick = function()
				if busy then
					return
				end
				busy = true
				hide(true)
				local evidence = hooks.present(index)
				hide(false)
				busy = false
				if evidence then
					layer:Destroy()
					resolve({ statement = index, evidence = evidence }, index)
				end
			end,
		})

		Kit.tween(panel, 0.3, { Position = UDim2.new(0.5, 0, 1, -16) }, Enum.EasingStyle.Quart)
		show(index)
		return nil
	end)
end

return Testimony
