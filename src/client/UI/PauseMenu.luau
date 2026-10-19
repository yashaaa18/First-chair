--[[
	PauseMenu — Resume / Restart case / Main menu. Returns the choice.
]]

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)

local PauseMenu = {}

local C = Theme.Colors
local open = false

function PauseMenu.show(caseTitle: string, music: { enabled: () -> boolean, toggle: () -> boolean }?): string?
	if open then
		return nil
	end
	open = true
	local result = Kit.await(function(resolve)
		local layer = Kit.new("Frame", {
			Name = "Pause",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = Root.popup,
		})
		Kit.scrim(layer, 0.35)
		local card = Kit.panel({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(360, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = layer,
		})
		Kit.padding(22).Parent = card
		Kit.list(Enum.FillDirection.Vertical, 12, Enum.HorizontalAlignment.Center).Parent = card
		Kit.text({
			Text = "PAUSED",
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Tiny + 1,
			TextColor3 = C.Accent,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, 0, 0, 16),
			LayoutOrder = 1,
			Parent = card,
		})
		Kit.text({
			Text = caseTitle,
			FontFace = Theme.Fonts.Display,
			TextSize = Theme.Text.Heading,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = 2,
			Parent = card,
		})
		local function option(text: string, id: string, style: string, order: number)
			Kit.button({
				text = text,
				style = style,
				size = UDim2.new(1, 0, 0, Theme.TouchHeight),
				layoutOrder = order,
				parent = card,
				onClick = function()
					layer:Destroy()
					resolve(id)
				end,
			})
		end
		option("Resume", "resume", "primary", 10)
		option("Restart Case", "restart", "secondary", 11)
		option("Main Menu", "menu", "ghost", 12)
		if music then
			local b: TextButton
			b = Kit.button({
				text = if music.enabled() then "Music: On" else "Music: Off",
				style = "ghost",
				size = UDim2.new(1, 0, 0, Theme.TouchHeight - 8),
				layoutOrder = 13,
				parent = card,
				onClick = function()
					b.Text = if music.toggle() then "Music: On" else "Music: Off"
				end,
			})
		end
		return nil
	end)
	open = false
	return result
end

return PauseMenu
