--[[
	Interview — pick topics to ask about. Each topic plays a short exchange.
	All topics must be heard before moving on (they hold the clues).
]]

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)

local Interview = {}

local C = Theme.Colors

function Interview.run(step, playLines: ({ any }) -> (), onMenu: (() -> ())?)
	local asked: { [number]: boolean } = {}
	local total = #step.topics
	while true do
		if onMenu then
			onMenu()
		end
		local choice = Kit.await(function(resolve)
			local layer = Kit.new("Frame", {
				Name = "Interview",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Parent = Root.modal,
			})
			local card = Kit.panel({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 20, 0.5, 20),
				Size = UDim2.fromOffset(360, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = layer,
			})
			Kit.padding(18, 20).Parent = card
			Kit.list(Enum.FillDirection.Vertical, 10).Parent = card
			Kit.text({
				Text = string.upper(step.prompt or "Ask about…"),
				FontFace = Theme.Fonts.Label,
				TextSize = Theme.Text.Tiny + 1,
				TextColor3 = C.Accent,
				Size = UDim2.new(1, 0, 0, 18),
				LayoutOrder = 0,
				Parent = card,
			})
			local count = 0
			for i, topic in step.topics do
				local done = asked[i] == true
				if done then
					count += 1
				end
				local b = Kit.button({
					text = (if done then "✓  " else "") .. topic.label,
					style = if done then "ghost" else "paper",
					align = Enum.TextXAlignment.Left,
					size = UDim2.new(1, 0, 0, Theme.TouchHeight - 4),
					layoutOrder = i,
					parent = card,
					onClick = function()
						layer:Destroy()
						resolve(i)
					end,
				})
				Kit.padding(0, 16).Parent = b
			end
			local finished = count >= total
			local cont = Kit.button({
				text = if finished then "Continue" else ("%d of %d topics"):format(count, total),
				style = "primary",
				size = UDim2.new(1, 0, 0, Theme.TouchHeight),
				layoutOrder = 100,
				parent = card,
				onClick = function()
					if finished then
						layer:Destroy()
						resolve(0)
					end
				end,
			})
			Kit.setEnabled(cont, finished)
			Kit.tween(card, 0.3, { Position = UDim2.new(1, -20, 0.5, 0) }, Enum.EasingStyle.Quart)
			return nil
		end)
		if choice == 0 then
			return
		end
		playLines(step.topics[choice].lines)
		asked[choice] = true
	end
end

return Interview
