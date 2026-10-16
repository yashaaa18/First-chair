--[[
	CameraDirector — cinematic, script-driven camera. The player never has to
	steer the camera: every scene, speaker and decision has a framed shot.
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local StageLayout = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").StageLayout)

local CameraDirector = {}

local camera: Camera = workspace.CurrentCamera
local currentTween: Tween? = nil
local fovTween: Tween? = nil
local driftTween: Tween? = nil
local loopToken = 0
local lastTarget: CFrame? = nil

local function cam(): Camera
	camera = workspace.CurrentCamera
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end
	return camera
end

local function stopAll()
	for _, t in { currentTween, fovTween, driftTween } do
		if t then
			t:Cancel()
		end
	end
	currentTween, fovTween, driftTween = nil, nil, nil
end

function CameraDirector.init()
	cam()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		cam()
		if lastTarget then
			camera.CFrame = lastTarget
		end
	end)
end

-- Instantly place the camera.
function CameraDirector.cut(cf: CFrame, fov: number?)
	loopToken += 1
	stopAll()
	local c = cam()
	c.CFrame = cf
	if fov then
		c.FieldOfView = fov
	end
	lastTarget = cf
end

-- Smoothly move the camera, then add a slow, subtle push-in (feels alive).
function CameraDirector.move(cf: CFrame, fov: number?, time: number?, drift: boolean?)
	loopToken += 1
	stopAll()
	local c = cam()
	local duration = time or 0.7
	if duration <= 0 then
		CameraDirector.cut(cf, fov)
	else
		local info = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local move = TweenService:Create(c, info, { CFrame = cf })
		move:Play()
		currentTween = move
		if fov then
			local zoom = TweenService:Create(c, info, { FieldOfView = fov })
			zoom:Play()
			fovTween = zoom
		end
	end
	lastTarget = cf
	if drift ~= false then
		local token = loopToken
		task.delay(duration, function()
			if token ~= loopToken then
				return
			end
			local pushed = cf * CFrame.new(0, 0, -0.6)
			local push = TweenService:Create(
				cam(),
				TweenInfo.new(9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ CFrame = pushed }
			)
			push:Play()
			driftTween = push
		end)
	end
end

function CameraDirector.shot(name: string, time: number?)
	local shot = StageLayout.Shots[name]
	if not shot then
		warn("[FirstChair] Unknown shot:", name)
		return
	end
	CameraDirector.move(shot.cf, shot.fov, time)
end

--[[
	Frame a character's face. `head` is the actor's Head part; `side` picks the
	shoulder (+1 right / -1 left) for a natural three-quarter angle.
]]
function CameraDirector.closeup(head: BasePart, facing: CFrame, side: number?, time: number?)
	local look = facing.LookVector
	local right = facing.RightVector
	local headPos = head.Position
	local eye = headPos + look * 6.2 + right * ((side or 1) * 1.9) + Vector3.new(0, 0.35, 0)
	local target = headPos - Vector3.new(0, 0.35, 0) + right * ((side or 1) * 0.15)
	CameraDirector.move(CFrame.lookAt(eye, target), 36, time or 0.6)
end

-- A short shake for dramatic beats (objections, verdicts).
function CameraDirector.shake(intensity: number?, duration: number?)
	local power = intensity or 0.6
	local length = duration or 0.35
	local c = cam()
	if driftTween then
		driftTween:Cancel()
		driftTween = nil
	end
	local base = lastTarget or c.CFrame
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		if t >= length then
			conn:Disconnect()
			c.CFrame = base
			return
		end
		local falloff = 1 - t / length
		local rx = (math.random() - 0.5) * math.rad(power) * falloff
		local ry = (math.random() - 0.5) * math.rad(power) * falloff
		c.CFrame = base * CFrame.Angles(rx, ry, 0)
	end)
	local fov = c.FieldOfView
	TweenService:Create(c, TweenInfo.new(0.08), { FieldOfView = fov - 4 }):Play()
	task.delay(0.1, function()
		TweenService:Create(c, TweenInfo.new(0.4, Enum.EasingStyle.Back), { FieldOfView = fov }):Play()
	end)
end

-- Slow ping-pong between two shots (main menu backdrop).
function CameraDirector.loop(a: string, b: string, seconds: number)
	CameraDirector.cut(StageLayout.Shots[a].cf, StageLayout.Shots[a].fov)
	loopToken += 1
	local token = loopToken
	task.spawn(function()
		local targets = { b, a }
		local i = 1
		while token == loopToken do
			local shot = StageLayout.Shots[targets[i]]
			local glide = TweenService:Create(
				cam(),
				TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ CFrame = shot.cf }
			)
			currentTween = glide
			glide:Play()
			glide.Completed:Wait()
			i = i % 2 + 1
		end
	end)
end

return CameraDirector
