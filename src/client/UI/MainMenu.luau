--[[
	MainMenu — the title screen and case selection.
	MainMenu.run(profile) yields until the player picks an unlocked case; returns its id.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CaseCatalog = require(Shared.CaseCatalog)

local MainMenu = {}

local C = Theme.Colors
local P = Theme.Palette

local function backdrop(): Frame
	local frame = Kit.new("Frame", {
		Name = "MenuBackdrop",
		BackgroundColor3 = P.NavyDeep,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = Root.backdropGui,
	})
	Kit.new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.45, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = frame,
	})
	return frame
end

local function howToPlay(parent: Instance)
	Kit.await(function(resolve)
		local layer = Kit.new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = parent,
		})
		Kit.scrim(layer, 0.4)
		local card = Kit.panel({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(560, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = layer,
		})
		Kit.padding(22, 26).Parent = card
		Kit.list(Enum.FillDirection.Vertical, 12).Parent = card
		Kit.text({
			Text = "How to play",
			FontFace = Theme.Fonts.Display,
			TextSize = Theme.Text.Heading,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = 1,
			Parent = card,
		})
		local tips = {
			{ "Tap", "anywhere to move dialogue along. Tap again to skip the typing." },
			{ "Read", "every exhibit — the key detail is highlighted for you." },
			{
				"Spot",
				"the lie: during testimony, flip through statements and Present the evidence that contradicts one.",
			},
			{ "Relax", "— wrong answers just cost points. You never have to restart a case." },
		}
		for i, tip in tips do
			Kit.text({
				Text = ('<font color="#CDAC70"><b>%s</b></font> %s'):format(tip[1], tip[2]),
				RichText = true,
				FontFace = Theme.Fonts.Body,
				TextSize = Theme.Text.Small + 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1 + i,
				Parent = card,
			})
		end
		Kit.button({
			text = "Got it",
			style = "primary",
			size = UDim2.new(1, 0, 0, Theme.TouchHeight),
			layoutOrder = 20,
			parent = card,
			onClick = function()
				layer:Destroy()
				resolve()
			end,
		})
		return nil
	end)
end

local function caseCard(parent: Instance, caseId: string, state, order: number, onPlay: () -> ()): Frame
	local info = CaseCatalog.get(caseId)
	local unlocked = state and state.unlocked
	local best = state and state.best
	local card = Kit.panel({
		Name = caseId,
		Size = UDim2.fromOffset(264, 330),
		LayoutOrder = order,
		BackgroundColor3 = if unlocked then P.Navy else P.NavyDeep,
		Parent = parent,
	})
	Kit.padding(18).Parent = card
	local scale = Kit.new("UIScale", { Scale = 0.9, Parent = card })
	task.delay(0.08 * order, function()
		Kit.tween(scale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	end)

	Kit.text({
		Text = ("CASE %02d"):format(info.number),
		FontFace = Theme.Fonts.Label,
		TextSize = Theme.Text.Tiny + 1,
		TextColor3 = if unlocked then C.Accent else C.TextDim,
		Size = UDim2.new(1, -50, 0, 18),
		Parent = card,
	})
	Kit.text({
		Text = info.title,
		FontFace = Theme.Fonts.Display,
		TextSize = Theme.Text.Heading + 2,
		TextColor3 = if unlocked then C.Text else C.TextDim,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 62),
		Parent = card,
	})
	Kit.new("Frame", {
		BackgroundColor3 = C.AccentDeep,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 92),
		Size = UDim2.fromOffset(48, 2),
		Parent = card,
	})
	Kit.text({
		Text = if unlocked then info.blurb else "Win the previous case to unlock this matter.",
		FontFace = Theme.Fonts.Body,
		TextSize = Theme.Text.Small,
		TextColor3 = C.TextDim,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(0, 104),
		Size = UDim2.new(1, 0, 0, 80),
		Parent = card,
	})
	Kit.text({
		Text = if unlocked then ("Client: %s  ·  %s"):format(info.client, info.minutes) else "",
		FontFace = Theme.Fonts.Label,
		TextSize = Theme.Text.Tiny,
		TextColor3 = C.TextDim,
		Position = UDim2.fromOffset(0, 190),
		Size = UDim2.new(1, 0, 0, 30),
		Parent = card,
	})
	if best then
		local medal = Kit.new("Frame", {
			BackgroundColor3 = P.NavyDeep,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, -4),
			Size = UDim2.fromOffset(42, 42),
			Parent = card,
		})
		Kit.corner(UDim.new(1, 0)).Parent = medal
		Kit.new("UIStroke", { Color = C.Accent, Thickness = 2, Parent = medal })
		Kit.text({
			Text = best.grade,
			FontFace = Theme.Fonts.Display,
			TextSize = Theme.Text.Heading,
			TextColor3 = C.Accent,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			Parent = medal,
		})
	elseif not unlocked then
		Kit.text({
			Text = "LOCKED",
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Tiny,
			TextColor3 = C.TextDim,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(80, 18),
			Parent = card,
		})
	end
	local play = Kit.button({
		text = if not unlocked then "Locked" elseif best then "Replay" else "Begin",
		style = if best then "secondary" else "primary",
		size = UDim2.new(1, 0, 0, Theme.TouchHeight),
		anchor = Vector2.new(0, 1),
		position = UDim2.fromScale(0, 1),
		parent = card,
		onClick = function()
			if unlocked then
				onPlay()
			end
		end,
	})
	Kit.setEnabled(play, unlocked == true)
	return card
end

export type Hooks = {
	onShow: () -> (),
	musicEnabled: (() -> boolean)?,
	onToggleMusic: (() -> boolean)?,
	startOnSelect: boolean?,
}

function MainMenu.run(profile, hooks: Hooks): string
	hooks.onShow()
	local back = backdrop()
	local result = Kit.await(function(resolve)
		local layer = Kit.new("Frame", {
			Name = "MainMenu",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = Root.menu,
		})

		----------------------------------------------------------------- title page
		local title = Kit.new("Frame", {
			Name = "Title",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(56, 0),
			Size = UDim2.new(0, 460, 1, 0),
			Parent = layer,
		})
		Kit.list(
			Enum.FillDirection.Vertical,
			10,
			Enum.HorizontalAlignment.Left,
			Enum.VerticalAlignment.Center
		).Parent =
			title
		Kit.text({
			Text = "VALENCE LEGAL PRESENTS",
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Tiny + 1,
			TextColor3 = C.Accent,
			Size = UDim2.new(1, 0, 0, 16),
			LayoutOrder = 1,
			Parent = title,
		})
		local heading = Kit.text({
			Text = "First Chair",
			FontFace = Theme.Fonts.Display,
			TextSize = Theme.Text.Hero,
			Size = UDim2.new(1, 0, 0, 78),
			LayoutOrder = 2,
			TextTransparency = 1,
			Parent = title,
		})
		Kit.tween(heading, 0.9, { TextTransparency = 0 })
		local rule = Kit.new("Frame", {
			BackgroundColor3 = C.Accent,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(0, 2),
			LayoutOrder = 3,
			Parent = title,
		})
		Kit.tween(rule, 0.9, { Size = UDim2.fromOffset(120, 2) }, Enum.EasingStyle.Quart)
		Kit.text({
			Text = "A courtroom drama in three cases. Find the lie. Win the room.",
			FontFace = Theme.Fonts.SerifItalic,
			TextSize = Theme.Text.Body - 1,
			TextColor3 = C.TextDim,
			Size = UDim2.new(1, 0, 0, 48),
			LayoutOrder = 4,
			Parent = title,
		})

		-- career card
		local career = Kit.panel({
			Size = UDim2.new(1, -60, 0, 74),
			LayoutOrder = 5,
			Parent = title,
		})
		Kit.padding(12, 16).Parent = career
		Kit.text({
			Text = "YOUR CAREER",
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Tiny,
			TextColor3 = C.Accent,
			Size = UDim2.new(1, 0, 0, 14),
			Parent = career,
		})
		Kit.text({
			Text = ("%s  ·  %d pts"):format(profile.title, profile.points),
			FontFace = Theme.Fonts.BodyBold,
			TextSize = Theme.Text.Body - 1,
			Position = UDim2.fromOffset(0, 16),
			Size = UDim2.new(1, 0, 0, 24),
			Parent = career,
		})
		local track = Kit.new("Frame", {
			BackgroundColor3 = P.NavySoft,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 44),
			Size = UDim2.new(1, 0, 0, 5),
			Parent = career,
		})
		Kit.corner(UDim.new(1, 0)).Parent = track
		local progress = if profile.nextPoints
			then math.clamp(profile.points / profile.nextPoints, 0, 1)
			else 1
		local fill = Kit.new("Frame", {
			BackgroundColor3 = C.Accent,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0, 1),
			Parent = track,
		})
		Kit.corner(UDim.new(1, 0)).Parent = fill
		Kit.tween(fill, 1.2, { Size = UDim2.fromScale(progress, 1) }, Enum.EasingStyle.Quart)

		local hasProgress = false
		for _, state in profile.cases do
			if state.best then
				hasProgress = true
			end
		end

		local buttons = Kit.new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, Theme.TouchHeight),
			LayoutOrder = 6,
			Parent = title,
		})
		Kit.list(Enum.FillDirection.Horizontal, 12).Parent = buttons

		----------------------------------------------------------------- case select page
		local select = Kit.new("Frame", {
			Name = "CaseSelect",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			Parent = layer,
		})
		Kit.text({
			Text = "Choose a matter",
			FontFace = Theme.Fonts.Display,
			TextSize = Theme.Text.Title,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 34),
			Size = UDim2.fromOffset(600, 40),
			Parent = select,
		})
		local cards = Kit.new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 10),
			Size = UDim2.new(1, -40, 0, 340),
			Parent = select,
		})
		Kit.list(
			Enum.FillDirection.Horizontal,
			18,
			Enum.HorizontalAlignment.Center,
			Enum.VerticalAlignment.Center
		).Parent =
			cards
		Kit.button({
			text = "‹  Back",
			style = "ghost",
			size = UDim2.fromOffset(130, 48),
			position = UDim2.fromOffset(24, 24),
			parent = select,
			onClick = function()
				select.Visible = false
				title.Visible = true
				back.Visible = true
			end,
		})

		local function openSelect()
			title.Visible = false
			back.Visible = false
			select.Visible = true
			cards:ClearAllChildren()
			Kit.list(
				Enum.FillDirection.Horizontal,
				18,
				Enum.HorizontalAlignment.Center,
				Enum.VerticalAlignment.Center
			).Parent =
				cards
			for i, caseId in CaseCatalog.order do
				caseCard(cards, caseId, profile.cases[caseId], i, function()
					layer:Destroy()
					resolve(caseId)
				end)
			end
		end

		Kit.button({
			text = if hasProgress then "Continue" else "Start Game",
			style = "primary",
			size = UDim2.fromOffset(190, Theme.TouchHeight),
			layoutOrder = 1,
			parent = buttons,
			onClick = openSelect,
		})
		Kit.button({
			text = "Explore the Office",
			style = "secondary",
			size = UDim2.fromOffset(210, Theme.TouchHeight),
			layoutOrder = 2,
			parent = buttons,
			onClick = function()
				layer:Destroy()
				resolve("__lobby")
			end,
		})
		local row2 = Kit.new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 44),
			LayoutOrder = 7,
			Parent = title,
		})
		Kit.list(Enum.FillDirection.Horizontal, 12).Parent = row2
		Kit.button({
			text = "How to Play",
			style = "ghost",
			textSize = Theme.Text.Small,
			size = UDim2.fromOffset(150, 44),
			layoutOrder = 1,
			parent = row2,
			onClick = function()
				howToPlay(layer)
			end,
		})
		if hooks.onToggleMusic then
			local musicButton: TextButton
			local function label(on: boolean)
				return if on then "Music: On" else "Music: Off"
			end
			musicButton = Kit.button({
				text = label(hooks.musicEnabled and hooks.musicEnabled() or true),
				style = "ghost",
				textSize = Theme.Text.Small,
				size = UDim2.fromOffset(150, 44),
				layoutOrder = 2,
				parent = row2,
				onClick = function()
					musicButton.Text = label((hooks.onToggleMusic :: () -> boolean)())
				end,
			})
		end
		if profile.streak and profile.streak >= 2 then
			Kit.text({
				Text = ("%d-day streak  ·  win a case today to keep it"):format(profile.streak),
				FontFace = Theme.Fonts.Label,
				TextSize = Theme.Text.Tiny + 1,
				TextColor3 = C.Accent,
				Size = UDim2.new(1, 0, 0, 18),
				LayoutOrder = 8,
				Parent = title,
			})
		end

		if profile.saving == false then
			Kit.text({
				Text = "Saving is unavailable right now — progress lasts until you leave.",
				FontFace = Theme.Fonts.Body,
				TextSize = Theme.Text.Tiny,
				TextColor3 = C.TextDim,
				Size = UDim2.new(1, 0, 0, 18),
				LayoutOrder = 9,
				Parent = title,
			})
		end
		-- Chapter Two teaser under the case cards
		Kit.text({
			Text = "CHAPTER TWO  ·  THE SILENT PARTNER  ·  IN DEVELOPMENT",
			FontFace = Theme.Fonts.Label,
			TextSize = Theme.Text.Tiny,
			TextColor3 = C.TextDim,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -22),
			Size = UDim2.new(1, -40, 0, 18),
			Parent = select,
		})
		if hooks.startOnSelect then
			openSelect()
		end
		return nil
	end)
	back:Destroy()
	return result
end

return MainMenu
