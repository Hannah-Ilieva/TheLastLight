-- MonsterService: the placeholder monster (a tall dark block with glowing eyes).
-- States:
--   Hidden    - not in the world (every phase except Blackout)
--   Hunting   - during Blackout it appears at a den and chases the nearest player
--               who is outside every safe light
--   Searching - if nobody can be chased, it walks to where it last saw someone, then waits
-- It never steps into a safe light, so it can't reach anyone standing inside one.
-- Everything here runs on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local log = require(ReplicatedStorage.Shared.Log)
local SafeZoneService = require(script.Parent.SafeZoneService)
local PlayerState = require(script.Parent.PlayerState)

local CONFIG = GameConfig.Monster
local BODY_SIZE = Vector3.new(3, 9, 3)
local RETARGET_INTERVAL = 0.5 -- seconds between "who is nearest?" checks
local PAUSE_AFTER_CATCH = 1.5 -- seconds it stands still after catching someone
local SAFE_ZONE_MARGIN = 2 -- keeps its body outside the light, not just its centre
local STEER_ANGLES = { 0, 45, -45, 90, -90 } -- directions tried when a safe light blocks the way

local MonsterService = {}

local monster: Model
local huntConnection: RBXScriptConnection?
local target: Player?
local lastSeenPosition: Vector3?
local retargetTimer = 0
local pausedUntil = 0

local function buildMonster(): Model
	local model = Instance.new("Model")
	model.Name = "Monster"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- visible from far away

	local function addPart(name, size, offset, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = CFrame.new(offset)
		part.Color = color
		part.Material = material
		part.Anchored = true
		part.CanCollide = false
		part.Parent = model
		return part
	end
	model.PrimaryPart = addPart("Body", BODY_SIZE, Vector3.zero, Color3.fromRGB(15, 15, 20), Enum.Material.SmoothPlastic)
	local eyeColor = Color3.fromRGB(200, 255, 230)
	addPart("LeftEye", Vector3.new(0.9, 0.45, 0.2), Vector3.new(-0.7, 3.4, -1.55), eyeColor, Enum.Material.Neon)
	addPart("RightEye", Vector3.new(0.9, 0.45, 0.2), Vector3.new(0.7, 3.4, -1.55), eyeColor, Enum.Material.Neon)

	-- A faint glow from the eyes so its shape shows in the dark, without lighting up the area.
	local glow = Instance.new("PointLight")
	glow.Color = eyeColor
	glow.Range = 10
	glow.Brightness = 0.8
	glow.Parent = model.PrimaryPart
	return model
end

local function getRoot(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

-- Distance on the ground, ignoring height.
local function flatDistance(a: Vector3, b: Vector3): number
	return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

-- The monster may chase players who are in the round and outside every safe light.
local function isPrey(player: Player): boolean
	return PlayerState.isActive(player) and not SafeZoneService.isPlayerSafe(player)
end

local function nearestPrey(from: Vector3): Player?
	local best, bestDistance = nil, math.huge
	for _, player in Players:GetPlayers() do
		local root = getRoot(player)
		if root and isPrey(player) then
			local distance = flatDistance(root.Position, from)
			if distance < bestDistance then
				best, bestDistance = player, distance
			end
		end
	end
	return best
end

-- Picks a den that is at least MinSpawnDistance from EVERY player, as close as possible
-- to a chaseable player. If everyone is safe, it lurks at the den closest to anyone,
-- ready for whoever steps out of the light. If no den is far enough, the farthest one.
local function chooseDen(): Vector3?
	local folder = workspace:FindFirstChild("MonsterSpawns")
	if not folder then
		return nil
	end
	local best, bestCloseness = nil, math.huge
	local farthest, farthestDistance = nil, -1
	for _, den in folder:GetChildren() do
		local nearestPlayer, nearestPreyDistance = math.huge, math.huge
		for _, player in Players:GetPlayers() do
			local root = getRoot(player)
			if root then
				local distance = flatDistance(root.Position, den.Position)
				nearestPlayer = math.min(nearestPlayer, distance)
				if isPrey(player) then
					nearestPreyDistance = math.min(nearestPreyDistance, distance)
				end
			end
		end
		-- If anyone can be chased, every den has a prey distance; otherwise use any player.
		local closeness = if nearestPreyDistance < math.huge then nearestPreyDistance else nearestPlayer
		if nearestPlayer >= CONFIG.MinSpawnDistance and closeness < bestCloseness then
			best, bestCloseness = den, closeness
		end
		if nearestPlayer > farthestDistance then
			farthest, farthestDistance = den, nearestPlayer
		end
	end
	local chosen = best or farthest
	return chosen and chosen.Position
end

-- Moves toward `direction`. If that would enter a safe light, tries turning a little;
-- if every direction is blocked, it waits where it is.
local function moveToward(position: Vector3, direction: Vector3, distance: number)
	for _, angle in STEER_ANGLES do
		local turned = CFrame.Angles(0, math.rad(angle), 0):VectorToWorldSpace(direction)
		local nextPosition = position + turned * distance
		if not SafeZoneService.isInsideZone(nextPosition, SAFE_ZONE_MARGIN) then
			monster:PivotTo(CFrame.lookAt(nextPosition, nextPosition + turned))
			return
		end
	end
end

-- Runs every frame during Blackout.
local function step(dt: number)
	if os.clock() < pausedUntil then
		return
	end

	retargetTimer -= dt
	if retargetTimer <= 0 or (target and not isPrey(target)) then
		retargetTimer = RETARGET_INTERVAL
		target = nearestPrey(monster:GetPivot().Position)
	end

	local root = target and getRoot(target)
	if root then
		lastSeenPosition = root.Position
	end
	if not lastSeenPosition then
		return -- nobody to chase or search for: wait
	end

	local position = monster:GetPivot().Position
	local distance = flatDistance(lastSeenPosition, position)
	if root and distance <= CONFIG.CatchDistance then
		PlayerState.catch(target)
		target, lastSeenPosition = nil, nil
		pausedUntil = os.clock() + PAUSE_AFTER_CATCH
		return
	end
	if distance < 1 then
		lastSeenPosition = nil -- reached the last known spot and found nobody
		return
	end

	local cycle = ReplicatedStorage:GetAttribute("Cycle") or 1
	local speed = CONFIG.SpeedByNight[cycle] or CONFIG.SpeedByNight[#CONFIG.SpeedByNight]
	local flatOffset = Vector3.new(lastSeenPosition.X - position.X, 0, lastSeenPosition.Z - position.Z)
	moveToward(position, flatOffset.Unit, math.min(speed * dt, distance))
end

local function startHunt()
	local den = chooseDen()
	if not den then
		warn("[TheLastLight] No monster dens in Workspace.MonsterSpawns")
		return
	end
	target, lastSeenPosition, retargetTimer, pausedUntil = nil, nil, 0, 0
	monster:PivotTo(CFrame.new(den.X, BODY_SIZE.Y / 2, den.Z))
	monster.Parent = workspace
	huntConnection = RunService.Heartbeat:Connect(step)
	log("Monster is hunting from", den)
end

local function stopHunt()
	if huntConnection then
		huntConnection:Disconnect()
		huntConnection = nil
	end
	monster.Parent = nil
	target, lastSeenPosition = nil, nil
	log("Monster retreated")
end

function MonsterService.start()
	monster = buildMonster()
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
		if ReplicatedStorage:GetAttribute("Phase") == "Blackout" then
			startHunt()
		elseif huntConnection then
			stopHunt()
		end
	end)
end

return MonsterService
