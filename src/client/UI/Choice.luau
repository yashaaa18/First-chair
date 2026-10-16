--[[
	Choice — a decision card: a short prompt and 2–4 large answer cards.
	Choice.ask(prompt, options, speakerName?) -> chosen index
]]

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)

local Choice = {}

local C = Theme.Colors
local LETTERS = { "A", "B", "C", "D", "E" }

function Choice.ask(prompt: string, options: { { text: string } }, speaker: string?): number
	return Kit.await(function(resolve)
		local layer = Kit.new("Frame", {
			Name = "Choice",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = Root.modal,
		})
		local scrim = Kit.scrim(layer, 1)
		Kit.tween(scrim, 0.3, { BackgroundTransparency = 0.5 })

		local card = Kit.panel({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 24),
			Size = UDim2.new(0, 640, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = layer,
		})
		Kit.padding(22, 26).Parent = card
		Kit.list(Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Center).Parent = card
		local scale = Kit.new("UIScale", { Scale = 0.96, Parent = card })

		if speaker then
			Kit.text({
				Text = string.upper(speaker),
				FontFace = Theme.Fonts.Label,
				TextSize = Theme.Text.Tiny,
				TextColor3 = C.Accent,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 16),
				LayoutOrder = 1,
				Parent = card,
			})
		end
		Kit.text({
			Text = prompt,
			FontFace = Theme.Fonts.Display,
			TextSize = Theme.Text.Heading,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			Parent = card,
		})
		Kit.new("Frame", {
			BackgroundColor3 = C.AccentDeep,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 80, 0, 1),
			LayoutOrder = 3,
			Parent = card,
		})

		local chosen = false
		for i, option in options do
			local button = Kit.button({
				text = "",
				style = "paper",
				size = UDim2.new(1, 0, 0, 0),
				layoutOrder = 10 + i,
				parent = card,
				onClick = function()
					if chosen then
						return
					end
					chosen = true
					Kit.tween(scrim, 0.2, { BackgroundTransparency = 1 })
					local t = Kit.tween(scale, 0.18, { Scale = 0.96 })
					Kit.tween(card, 0.18, { BackgroundTransparency = 1 })
					t.Completed:Connect(function()
						layer:Destroy()
						resolve(i)
					end)
				end,
			})
			button.AutomaticSize = Enum.AutomaticSize.Y
			Kit.new("UISizeConstraint", { MinSize = Vector2.new(0, Theme.TouchHeight), Parent = button })
			Kit.padding(12, 16, 12, 60).Parent = button
			local badge = Kit.new("Frame", {
				BackgroundColor3 = C.Panel,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, -46, 0.5, 0),
				Size = UDim2.new(0, 30, 0, 30),
				Parent = button,
			})
			Kit.corner(UDim.new(1, 0)).Parent = badge
			Kit.text({
				Text = LETTERS[i] or tostring(i),
				FontFace = Theme.Fonts.BodyBold,
				TextSize = Theme.Text.Small,
				TextColor3 = C.Accent,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.fromScale(1, 1),
				Parent = badge,
			})
			Kit.text({
				Text = option.text,
				FontFace = Theme.Fonts.Label,
				TextSize = Theme.Text.Body - 1,
				TextColor3 = C.Ink,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = button,
			})
		end

		Kit.tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		Kit.tween(card, 0.3, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Enum.EasingStyle.Quart)
		return nil
	end)
end

return Choice
