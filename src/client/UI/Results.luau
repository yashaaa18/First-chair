--[[
	Results — the "Case Closed" screen: grade medallion, animated score,
	promotion points, rank-ups and the next case unlocking.
	Returns "menu" | "replay" | "next".
]]

local RunService = game:GetService("RunService")

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)

local CaseCatalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").CaseCatalog)

local Results = {}

local C = Theme.Colors
local P = Theme.Palette

local GRADE_LINE = {
	S = "Flawless. Mara almost smiled.",
	A = "Excellent work, counsel.",
	B = "A solid win. Sharpen the edges.",
	C = "A win is a win. Barely.",
}

local function countUp(label: TextLabel, to: number, max: number, duration: number)
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if not label.Parent then
			conn:Disconnect()
			return
		end
		local t = math.clamp((os.clock() - start) / duration, 0, 1)
		local eased = 1 - (1 - t) ^ 3
		label.Text = ("%d / %d"):format(math.floor(to * eased + 0.5), max)
		if t >= 1 then
			conn:Disconnect()
		end
	end)
end

local function stat(parent: Instance, title: string, value: string, order: number)
	local box = Kit.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(130, 52),
		LayoutOrder = order,
		Parent = parent,
	})
	Kit.text({
		Text = value,
		FontFace = Theme.Fonts.Display,
		TextSize = Theme.Text.Heading,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 30),
		Parent = box,
	})
	Kit.text({
		Text = title,
		FontFace = Theme.Fonts.Label,
		TextSize = Theme.Text.Tiny,
		TextColor3 = C.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 16),
		Parent = box,
	})
end

function Results.show(results, caseTitle: string, sounds: { gavel: () -> (), unlock: () -> () }): string
	return Kit.await(function(resolve)
		local layer = Kit.new("Frame", {
			Name = "Results",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 25,
			Parent = Root.overlay,
		})
		local scrim = Kit.scrim(layer, 1)
		scrim.ZIndex = 25
		Kit.tween(scrim, 0.4, { BackgroundTransparency = 0.25 })

		local card = Kit.panel({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 30),
			Size = UDim2.fromOffset(640, 470),
			ZIndex = 26,
			Parent = layer,
		})
		Kit.padding(20, 28).Parent = card
		Kit.tween(card, 0.45, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Quart)

		local function t(props)
			props.ZIndex = 27
			props.Parent = props.Parent or card
			return Kit.text(props)
		end

		t({
			Text = "CASE CLOSED",
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Small,
			TextColor3 = C.Accent,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, 0, 0, 18),
		})
		t({
			Text = caseTitle,
			FontFace = Theme.Fonts.Display,
			TextSize = Theme.Text.Title,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(0, 22),
			Size = UDim2.new(1, 0, 0, 38),
		})

		-- grade medallion
		local medal = Kit.new("Frame", {
			BackgroundColor3 = P.NavyDeep,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 72),
			Size = UDim2.fromOffset(112, 112),
			ZIndex = 27,
			Parent = card,
		})
		Kit.corner(UDim.new(1, 0)).Parent = medal
		Kit.new("UIStroke", { Color = C.Accent, Thickness = 3, Parent = medal })
		local gradeLabel = Kit.text({
			Text = results.grade,
			FontFace = Theme.Fonts.Display,
			TextSize = 60,
			TextColor3 = C.Accent,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 28,
			Parent = medal,
		})
		local medalScale = Kit.new("UIScale", { Scale = 0, Parent = medal })
		task.delay(0.35, function()
			sounds.gavel()
			Kit.tween(medalScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
		end)
		gradeLabel.Name = "Grade"

		t({
			Text = GRADE_LINE[results.grade] or "",
			FontFace = Theme.Fonts.SerifItalic,
			TextSize = Theme.Text.Small + 1,
			TextColor3 = C.TextDim,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(0, 192),
			Size = UDim2.new(1, 0, 0, 22),
		})

		local score = t({
			Text = ("0 / %d"):format(results.maxScore),
			FontFace = Theme.Fonts.Display,
			TextSize = 34,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(0, 220),
			Size = UDim2.new(1, 0, 0, 40),
		})
		task.delay(0.5, function()
			countUp(score, results.score, results.maxScore, 1.2)
		end)

		local stats = Kit.new("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 266),
			Size = UDim2.new(1, 0, 0, 52),
			ZIndex = 27,
			Parent = card,
		})
		Kit.list(Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Center).Parent = stats
		stat(stats, "ACCURACY", ("%d%%"):format(results.percent), 1)
		stat(stats, "MISTAKES", tostring(results.mistakes), 2)
		stat(stats, "FIRST-TRY", ("%d/%d"):format(results.perfectSteps, results.scoredSteps), 3)
		local profile = results.profile
		stat(stats, "PROMOTION PTS", ("+%d"):format(results.pointsEarned or 0), 4)
		for _, d in stats:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = 27
			end
		end

		-- career line
		local career = if profile
			then ("%s  ·  %d promotion points"):format(profile.title, profile.points)
			else ""
		if results.rankUp then
			career = "PROMOTED — " .. results.rankUp
		end
		t({
			Text = career,
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Small,
			TextColor3 = if results.rankUp then C.Accent else C.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(0, 326),
			Size = UDim2.new(1, 0, 0, 20),
		})
		if results.dailyBonus then
			t({
				Text = ("Daily bonus  +%d pts   ·   %d-day streak"):format(
					results.dailyBonus,
					results.streak or 1
				),
				FontFace = Theme.Fonts.Label,
				TextSize = Theme.Text.Tiny + 1,
				TextColor3 = C.Success,
				TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromOffset(0, 346),
				Size = UDim2.new(1, 0, 0, 16),
			})
		end
		if results.saved == false then
			t({
				Text = "Progress couldn't be saved this session.",
				FontFace = Theme.Fonts.Body,
				TextSize = Theme.Text.Tiny,
				TextColor3 = C.Danger,
				TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromOffset(0, 364),
				Size = UDim2.new(1, 0, 0, 16),
			})
		end

		-- buttons
		local footer = Kit.new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, Theme.TouchHeight),
			ZIndex = 27,
			Parent = card,
		})
		Kit.list(Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Center).Parent = footer
		local function choose(id: string)
			Kit.tween(scrim, 0.25, { BackgroundTransparency = 1 })
			local tw =
				Kit.tween(card, 0.25, { Position = UDim2.new(0.5, 0, 0.5, 30), BackgroundTransparency = 1 })
			tw.Completed:Connect(function()
				layer:Destroy()
				resolve(id)
			end)
		end
		local buttons = {
			Kit.button({
				text = "Replay",
				style = "secondary",
				size = UDim2.fromOffset(150, Theme.TouchHeight),
				layoutOrder = 1,
				parent = footer,
				onClick = function()
					choose("replay")
				end,
			}),
			Kit.button({
				text = "Main Menu",
				style = "secondary",
				size = UDim2.fromOffset(170, Theme.TouchHeight),
				layoutOrder = 2,
				parent = footer,
				onClick = function()
					choose("menu")
				end,
			}),
		}
		local index = CaseCatalog.indexOf(results.caseId)
		local nextId = index and CaseCatalog.order[index + 1]
		if nextId and profile and profile.cases[nextId] and profile.cases[nextId].unlocked then
			table.insert(
				buttons,
				Kit.button({
					text = "Next Case  ›",
					style = "primary",
					size = UDim2.fromOffset(190, Theme.TouchHeight),
					layoutOrder = 3,
					parent = footer,
					onClick = function()
						choose("next")
					end,
				})
			)
		end
		for _, b in buttons do
			b.ZIndex = 28
		end

		-- unlock ribbon
		if results.unlocked then
			local info = CaseCatalog.get(results.unlocked)
			local ribbon = Kit.new("Frame", {
				BackgroundColor3 = P.Brass,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0, -10),
				Size = UDim2.fromOffset(0, 46),
				ClipsDescendants = true,
				ZIndex = 29,
				Parent = card,
			})
			Kit.corner(Theme.RadiusSmall).Parent = ribbon
			Kit.text({
				Text = ("CASE %d UNLOCKED  ·  %s"):format(info.number, string.upper(info.title)),
				FontFace = Theme.Fonts.BodyBold,
				TextSize = Theme.Text.Small,
				TextColor3 = P.NavyDeep,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextWrapped = false,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 30,
				Parent = ribbon,
			})
			task.delay(1.8, function()
				sounds.unlock()
				Kit.tween(ribbon, 0.6, { Size = UDim2.fromOffset(460, 46) }, Enum.EasingStyle.Back)
			end)
		end
		return nil
	end)
end

return Results
