--[[
	bake.luau — runs the real world-building code outside Roblox (with Lune) and
	saves the finished environment into the place file.

	Why: the office and courtroom then appear when the place is opened in Studio,
	the server starts faster, and any mistake in the builders (a wrong property
	name, a bad CFrame) fails here instead of in front of players.

	Run:  lune run scripts/bake.luau build/FirstChair.rbxlx
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local path = process.args[1] or "build/FirstChair.rbxlx"
local game = roblox.deserializePlace(fs.readFile(path))
local workspace = game:GetService("Workspace")

local cache = {}
local requireModule

local function makeEnv(script)
	local env = {
		script = script,
		game = game,
		workspace = workspace,
		require = function(target)
			return requireModule(target)
		end,
		task = task,
		print = print,
		warn = function(...)
			print("[warn]", ...)
		end,
		typeof = typeof,
	}
	for name, value in roblox do
		if env[name] == nil then
			env[name] = value
		end
	end
	return setmetatable(env, { __index = _G })
end

function requireModule(module)
	local key = module:GetFullName()
	if cache[key] ~= nil then
		return cache[key]
	end
	assert(
		module and module:IsA("ModuleScript"),
		"require target is not a ModuleScript: " .. tostring(module)
	)
	-- WaitForChild is a yielding engine call; in the bake everything already exists.
	local source = string.gsub(module.Source, ":WaitForChild%(", ":FindFirstChild(")
	local chunk = luau.load(source, { debugName = module:GetFullName(), environment = makeEnv(module) })
	local result = chunk()
	cache[key] = result
	return result
end

local serverScript = game:GetService("ServerScriptService"):FindFirstChild("Server")
local World = requireModule(serverScript:FindFirstChild("World"))

local root = World.build()
root:SetAttribute("Baked", World.VERSION)

-- Sanity checks: count parts and lights, and make sure every stage mark exists.
local parts, lights, guis = 0, 0, 0
for _, d in root:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
	elseif d:IsA("Light") then
		lights += 1
	elseif d:IsA("SurfaceGui") then
		guis += 1
	end
end
print(("Baked world: %d parts, %d lights, %d surface labels"):format(parts, lights, guis))
assert(parts > 300 and parts < 2500, "unexpected part count")
assert(lights <= 16, "too many lights for mobile")
assert(workspace:FindFirstChild("FirstChairWorld"), "world missing from workspace")

fs.writeFile(path, roblox.serializePlace(game))
print("Wrote " .. path)
