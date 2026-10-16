--[[
	Dialogue — the cinematic subtitle panel.

	Dialogue.play(lines, { skippable, onLine }) yields until the conversation ends.
	Tap anywhere (or press Space/Enter) to finish the current line, tap again to
	advance. "Skip" appears for conversations the player has already seen.
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)

local Dialogue = {}

local C = Theme.Colors
local CHARS_PER_SECOND = 58

export type Line = { any }
export type Options = {
	skippable: boolean?,
	onLine: ((Line, number) -> ())?,
	nameOf: (string) -> (string, string),
}

function Dialogue.play(lines: { Line }, opts: Options): string
	return Kit.await(function(resolve)
		local layer = Kit.new("Frame", {
			Name = "DialogueLayer",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = Root.dialogue,
		})
		-- Tap anywhere on the scene to advance.
		local catcher = Kit.new("TextButton", {
			Name = "TapCatcher",
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = layer,
		})
		-- Soft gradient so text is readable over any scene.
		local shade = Kit.new("Frame", {
			BackgroundColor3 = C.Scrim,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 260),
			BackgroundTransparency = 0,
			Parent = layer,
		})
		Kit.new("UIGradient", {
			Rotation = -90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.35),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = shade,
		})

		local panel = Kit.new("TextButton", {
			Name = "Panel",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = C.Panel,
			BackgroundTransparency = Theme.PanelTransparency,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -16 + 30),
			Size = UDim2.new(1, -48, 0, 150),
			Parent = layer,
		})
		Kit.corner().Parent = panel
		Kit.stroke(C.AccentDeep, 1, 0.5).Parent = panel
		Kit.new("UISizeConstraint", { MaxSize = Vector2.new(900, 150), Parent = panel })

		local nameTab = Kit.new("Frame", {
			Name = "NameTab",
			BackgroundColor3 = C.AccentDeep,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 22, 0, -17),
			Size = UDim2.new(0, 0, 0, 34),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = panel,
		})
		Kit.corner(Theme.RadiusSmall).Parent = nameTab
		Kit.padding(0, 14).Parent = nameTab
		Kit.list(
			Enum.FillDirection.Horizontal,
			10,
			Enum.HorizontalAlignment.Left,
			Enum.VerticalAlignment.Center
		).Parent =
			nameTab
		local nameLabel = Kit.text({
			Text = "",
			FontFace = Theme.Fonts.BodyBold,
			TextSize = Theme.Text.Small + 2,
			TextColor3 = C.Panel,
			TextWrapped = false,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			LayoutOrder = 1,
			Parent = nameTab,
		})
		local roleLabel = Kit.text({
			Text = "",
			FontFace = Theme.Fonts.Body,
			TextSize = Theme.Text.Tiny + 1,
			TextColor3 = C.Panel,
			TextTransparency = 0.25,
			TextWrapped = false,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			LayoutOrder = 2,
			Parent = nameTab,
		})

		local body = Kit.text({
			Name = "Body",
			Text = "",
			FontFace = Theme.Fonts.Body,
			TextSize = Theme.Text.Body + 1,
			LineHeight = 1.15,
			TextYAlignment = Enum.TextYAlignment.Top,
			Position = UDim2.new(0, 26, 0, 30),
			Size = UDim2.new(1, -52, 1, -50),
			Parent = panel,
		})

		local prompt = Kit.text({
			Text = "TAP  ›",
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Tiny,
			TextColor3 = C.Accent,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -18, 1, -10),
			Size = UDim2.new(0, 80, 0, 16),
			Visible = false,
			Parent = panel,
		})

		local finished = false
		local function finish(how: string)
			if finished then
				return
			end
			finished = true
			local t =
				Kit.tween(panel, 0.18, { Position = UDim2.new(0.5, 0, 1, 20), BackgroundTransparency = 1 })
			Kit.tween(shade, 0.18, { BackgroundTransparency = 1 })
			t.Completed:Connect(function()
				layer:Destroy()
				resolve(how)
			end)
		end

		if opts.skippable then
			Kit.button({
				text = "SKIP  »",
				style = "ghost",
				textSize = Theme.Text.Tiny + 1,
				size = UDim2.new(0, 96, 0, 34),
				anchor = Vector2.new(1, 0),
				position = UDim2.new(1, -16, 0, -17),
				parent = panel,
				onClick = function()
					finish("skipped")
				end,
			})
		end

		local index = 0
		local typing = false
		local typeConn: RBXScriptConnection? = nil
		local total = 0

		local function completeLine()
			if typeConn then
				typeConn:Disconnect()
				typeConn = nil
			end
			typing = false
			body.MaxVisibleGraphemes = -1
			prompt.Visible = true
		end

		local function showLine(i: number)
			local line = lines[i]
			local speaker, text = line[1], line[2]
			if opts.onLine then
				task.spawn(opts.onLine, line, i)
			end
			if speaker == "narrator" then
				nameTab.Visible = false
				body.FontFace = Theme.Fonts.SerifItalic
				body.TextColor3 = C.Accent
				body.TextXAlignment = Enum.TextXAlignment.Center
			else
				local name, role = opts.nameOf(speaker)
				nameTab.Visible = true
				nameLabel.Text = string.upper(name)
				roleLabel.Text = role
				roleLabel.Visible = role ~= ""
				nameTab.BackgroundColor3 = if speaker == "player" then C.Paper else C.AccentDeep
				local aside = string.sub(text, 1, 1) == "("
				body.FontFace = if aside then Theme.Fonts.SerifItalic else Theme.Fonts.Body
				body.TextColor3 = if aside then C.TextDim else C.Text
				body.TextXAlignment = Enum.TextXAlignment.Left
			end
			body.Text = text
			total = utf8.len(text) or #text
			body.MaxVisibleGraphemes = 0
			prompt.Visible = false
			typing = true
			local start = os.clock()
			typeConn = RunService.Heartbeat:Connect(function()
				local shown = math.floor((os.clock() - start) * CHARS_PER_SECOND)
				if shown >= total then
					completeLine()
				else
					body.MaxVisibleGraphemes = shown
				end
			end)
		end

		local function advance()
			if finished then
				return
			end
			if typing then
				completeLine()
				return
			end
			index += 1
			if index > #lines then
				finish("done")
			else
				showLine(index)
			end
		end

		catcher.Activated:Connect(advance)
		panel.Activated:Connect(advance)
		local keyConn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if
				input.KeyCode == Enum.KeyCode.Space
				or input.KeyCode == Enum.KeyCode.Return
				or input.KeyCode == Enum.KeyCode.ButtonA
			then
				advance()
			end
		end)
		layer.Destroying:Connect(function()
			keyConn:Disconnect()
			if typeConn then
				typeConn:Disconnect()
			end
		end)

		Kit.tween(panel, 0.25, { Position = UDim2.new(0.5, 0, 1, -16) }, Enum.EasingStyle.Quart)
		advance()
		return nil
	end)
end

return Dialogue
