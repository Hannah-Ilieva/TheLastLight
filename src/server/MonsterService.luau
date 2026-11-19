-- MonsterService: the Hollow Stag (its look is built by MonsterModel).
-- States:
--   Hidden    - not in the world (Lobby, Gather, Release, Results)
--   Stalking  - during the Warning it stands still at a distant den, facing the players,
--               and growls. A warning glimpse only: it cannot catch anyone yet.
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
local PowerService = require(script.Parent.PowerService)
local MonsterModel = require(script.Parent.MonsterModel)

local CONFIG = GameConfig.Monster
local RETARGET_INTERVAL = 0.5 -- seconds between "who is nearest?" checks
local PAUSE_AFTER_CATCH = 1.5 -- seconds it stands still after catching someone
local SAFE_ZONE_MARGIN = 2 -- keeps its body outside the light, not just its centre
local STEER_ANGLES = { 0, 45, -45, 90, -90 } -- directions tried when a safe light blocks the way
local STALK_EXTRA_DISTANCE = 20 -- while stalking it stays this much farther away than MinSpawnDistance
local GROWL_INTERVAL = NumberRange.new(5, 9) -- seconds between growls while hunting
local STRIDE_BOB = 0.18 -- how much it rises and falls with each step (studs)

local MonsterService = {}

local monster: Model
local huntConnection: RBXScriptConnection?
local target: Player?
local lastSeenPosition: Vector3?
local retargetTimer = 0
local pausedUntil = 0
local nextGrowlAt = 0
local walked = 0 -- distance walked, drives the stepping bob
local rng = Random.new()

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

-- Picks a den that is at least `minDistance` from EVERY player, as close as possible
-- to a chaseable player. If everyone is safe, it lurks at the den closest to anyone,
-- ready for whoever steps out of the light. If no den is far enough, the farthest one.
local function chooseDen(minDistance: number): Vector3?
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
		if nearestPlayer >= minDistance and closeness < bestCloseness then
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
			walked += distance
			local bob = math.abs(math.sin(walked * 0.9)) * STRIDE_BOB
			local standing = Vector3.new(nextPosition.X, MonsterModel.ROOT_HEIGHT + bob, nextPosition.Z)
			monster:PivotTo(CFrame.lookAt(standing, standing + turned))
			return
		end
	end
end

-- A Guardian Cap blocked the catch: the monster is thrown back (never into a light)
-- and stands still for a moment, giving the player time to run.
local function knockBack(position: Vector3, playerPosition: Vector3)
	local away = Vector3.new(position.X - playerPosition.X, 0, position.Z - playerPosition.Z)
	if away.Magnitude > 0.1 then
		local landing = position + away.Unit * GameConfig.Powers.ShieldKnockback
		if not SafeZoneService.isInsideZone(landing, SAFE_ZONE_MARGIN) then
			monster:PivotTo(CFrame.lookAt(landing, Vector3.new(playerPosition.X, landing.Y, playerPosition.Z)))
		end
	end
	pausedUntil = os.clock() + GameConfig.Powers.ShieldStunSeconds
end

local function growl()
	local sound = monster:FindFirstChild("Growl", true)
	if sound then
		sound:Play()
	end
	nextGrowlAt = os.clock() + rng:NextNumber(GROWL_INTERVAL.Min, GROWL_INTERVAL.Max)
end

-- Puts the monster at a den, turned toward the nearest player.
local function appearAt(den: Vector3)
	local standing = Vector3.new(den.X, MonsterModel.ROOT_HEIGHT, den.Z)
	local facing = standing - Vector3.new(0, 0, 1)
	local nearest, nearestDistance = nil, math.huge
	for _, player in Players:GetPlayers() do
		local root = getRoot(player)
		if root and flatDistance(root.Position, standing) < nearestDistance then
			nearest, nearestDistance = root, flatDistance(root.Position, standing)
		end
	end
	if nearest then
		facing = Vector3.new(nearest.Position.X, standing.Y, nearest.Position.Z)
	end
	monster:PivotTo(CFrame.lookAt(standing, facing))
	monster.Parent = workspace
end

-- Runs every frame during Blackout.
local function step(dt: number)
	if os.clock() < pausedUntil then
		return
	end

	if os.clock() >= nextGrowlAt then
		growl()
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
		if PowerService.absorbCatch(target) then
			knockBack(position, root.Position)
		else
			PlayerState.catch(target)
			PowerService.clear(target)
			pausedUntil = os.clock() + PAUSE_AFTER_CATCH
		end
		target, lastSeenPosition = nil, nil
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

local function stopHunt()
	if huntConnection then
		huntConnection:Disconnect()
		huntConnection = nil
	end
	target, lastSeenPosition = nil, nil
end

local function hide()
	stopHunt()
	if monster.Parent then
		monster.Parent = nil
		log("Monster retreated")
	end
end

-- Warning: a distant glimpse and a growl, but no hunting yet.
local function startStalking()
	local den = chooseDen(CONFIG.MinSpawnDistance + STALK_EXTRA_DISTANCE)
	if den then
		appearAt(den)
		growl()
		log("Monster is stalking from", den)
	end
end

local function startHunt()
	local den = chooseDen(CONFIG.MinSpawnDistance)
	if not den then
		warn("[TheLastLight] No monster dens in Workspace.MonsterSpawns")
		return
	end
	stopHunt()
	target, lastSeenPosition, retargetTimer, pausedUntil = nil, nil, 0, 0
	appearAt(den)
	growl()
	huntConnection = RunService.Heartbeat:Connect(step)
	log("Monster is hunting from", den)
end

function MonsterService.start()
	monster = MonsterModel.build()
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
		local phase = ReplicatedStorage:GetAttribute("Phase")
		if phase == "Blackout" then
			startHunt()
		elseif phase == "Warning" then
			startStalking()
		else
			hide()
		end
	end)
end

return MonsterService
