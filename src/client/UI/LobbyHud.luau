--[[
	LobbyHud — the small overlay while walking around Valence Legal.
	Returns "cases" (open the case files) or "menu" (back to the title screen).
]]

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)

local LobbyHud = {}

local C = Theme.Colors

function LobbyHud.run(profile, onPrompt: (() -> ()) -> RBXScriptConnection?): string
	return Kit.await(function(resolve)
		local layer = Kit.new("Frame", {
			Name = "LobbyHud",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = Root.hud,
		})
		local function finish(result: string)
			layer:Destroy()
			resolve(result)
		end

		local buttons = Kit.new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 12),
			Size = UDim2.fromOffset(340, 50),
			Parent = layer,
		})
		Kit.list(Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Right).Parent = buttons
		Kit.button({
			text = "Case Files",
			style = "primary",
			textSize = Theme.Text.Small,
			size = UDim2.fromOffset(160, 50),
			layoutOrder = 1,
			parent = buttons,
			onClick = function()
				finish("cases")
			end,
		})
		Kit.button({
			text = "Menu",
			style = "secondary",
			textSize = Theme.Text.Small,
			size = UDim2.fromOffset(110, 50),
			layoutOrder = 2,
			parent = buttons,
			onClick = function()
				finish("menu")
			end,
		})

		local badge = Kit.panel({
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.new(0, 14, 0, 12),
			Size = UDim2.fromOffset(0, 50),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = layer,
		})
		Kit.padding(6, 16).Parent = badge
		Kit.text({
			Text = string.upper(profile.title),
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Tiny,
			TextColor3 = C.Accent,
			TextWrapped = false,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 16),
			Parent = badge,
		})
		Kit.text({
			Text = ("%d promotion points"):format(profile.points),
			FontFace = Theme.Fonts.BodyBold,
			TextSize = Theme.Text.Small,
			TextWrapped = false,
			AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.fromOffset(0, 18),
			Size = UDim2.fromOffset(0, 20),
			Parent = badge,
		})

		local hint = Kit.text({
			Text = "Walk to the ACTIVE MATTERS board and tap it, or use Case Files.",
			FontFace = Theme.Fonts.Body,
			TextSize = Theme.Text.Small,
			TextColor3 = C.TextDim,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -18),
			Size = UDim2.new(1, -40, 0, 22),
			Parent = layer,
		})
		task.delay(7, function()
			if hint.Parent then
				Kit.tween(hint, 0.6, { TextTransparency = 1 })
			end
		end)

		local conn = onPrompt(function()
			finish("cases")
		end)
		return function()
			if conn then
				conn:Disconnect()
			end
		end
	end)
end

return LobbyHud
