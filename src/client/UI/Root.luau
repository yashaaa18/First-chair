--[[
	Root — the three ScreenGuis and the scaled 960×560 canvas everything sits on.

	  Backdrop (order 1)  full-bleed menu backdrop
	  Main     (order 5)  HUD, dialogue, modals, toasts (inside device safe area)
	  Overlay  (order 20) fades, objection, verdict, results

	Each GUI holds a "Canvas" frame sized in reference pixels and scaled with a
	UIScale, so layouts look the same on a phone, an iPad and a monitor.
]]

local Players = game:GetService("Players")

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)

local Root = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local canvases: { Frame } = {}
Root.scale = 1

local function makeGui(name: string, order: number, insets: Enum.ScreenInsets): (ScreenGui, Frame)
	local existing = playerGui:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local gui = Kit.new("ScreenGui", {
		Name = name,
		DisplayOrder = order,
		ResetOnSpawn = false,
		ScreenInsets = insets, -- (replaces the older IgnoreGuiInset flag)
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})
	local canvas = Kit.new("Frame", {
		Name = "Canvas",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.zero,
		Position = UDim2.new(),
		Parent = gui,
	})
	Kit.new("UIScale", { Parent = canvas })
	table.insert(canvases, canvas)
	return gui, canvas
end

local function layer(parent: Instance, name: string, z: number): Frame
	return Kit.new("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
		Parent = parent,
	})
end

local function rescale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local ref = Theme.Reference
	local s = math.clamp(math.min(viewport.X / ref.X, viewport.Y / ref.Y), 0.5, 1.7)
	Root.scale = s
	for _, canvas in canvases do
		canvas.Size = UDim2.fromScale(1 / s, 1 / s)
		local uiScale = canvas:FindFirstChildOfClass("UIScale")
		if uiScale then
			uiScale.Scale = s
		end
	end
end

function Root.init()
	local backdropGui, backdrop = makeGui("FirstChair_Backdrop", 1, Enum.ScreenInsets.None)
	local mainGui, main = makeGui("FirstChair_Main", 5, Enum.ScreenInsets.DeviceSafeInsets)
	local overlayGui, overlay = makeGui("FirstChair_Overlay", 20, Enum.ScreenInsets.None)

	Root.backdropGui, Root.mainGui, Root.overlayGui = backdropGui, mainGui, overlayGui
	Root.backdrop = backdrop
	Root.menu = layer(main, "Menu", 1)
	Root.hud = layer(main, "Hud", 2)
	Root.dialogue = layer(main, "Dialogue", 3)
	Root.modal = layer(main, "Modal", 4)
	Root.popup = layer(main, "Popup", 5)
	Root.toast = layer(main, "Toast", 6)
	Root.overlay = overlay

	rescale()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		rescale()
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end)
end

-- Remove everything a case put on screen (used when quitting or restarting).
function Root.clearCaseUi()
	for _, frame in { Root.dialogue, Root.modal, Root.popup } do
		frame:ClearAllChildren()
	end
end

return Root
