-- SafeZoneService: decides, on the server, who is standing inside a safe light.
-- A player is safe when their HumanoidRootPart (the centre of the character) is inside
-- one of the circles in Workspace.SafeZones, during a phase in GameConfig.SafeZonePhases.
--
-- The result is published as a "Safe" attribute on each Player so the HUD can show it.
-- Other server scripts (the monster, later) call SafeZoneService.isPlayerSafe(player).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local log = require(ReplicatedStorage.Shared.Log)

local CHECK_INTERVAL = 0.2 -- seconds between checks
-- How far below or above a circle the character's centre may be and still count
-- (the centre is about 3 studs above the ground, and players can jump).
local HEIGHT_BELOW = 4
local HEIGHT_ABOVE = 12

local SafeZoneService = {}

local zones = {} -- list of { center: Vector3, radius: number }

-- Reads the circles once. The circles are cylinders lying flat, so their diameter is Size.Y.
local function loadZones()
	local folder = workspace:FindFirstChild("SafeZones")
	if not folder then
		return -- Main already warns about the missing folder
	end
	for _, disc in folder:GetChildren() do
		if disc:IsA("BasePart") then
			table.insert(zones, { center = disc.Position, radius = disc.Size.Y / 2 })
		end
	end
end

-- True if a world position is inside any safe circle (ignores the phase).
function SafeZoneService.isInsideZone(position: Vector3): boolean
	for _, zone in zones do
		local offset = position - zone.center
		local flatDistance = Vector2.new(offset.X, offset.Z).Magnitude
		if flatDistance <= zone.radius and offset.Y >= -HEIGHT_BELOW and offset.Y <= HEIGHT_ABOVE then
			return true
		end
	end
	return false
end

-- True if the player is protected right now: protection is active and they are inside a circle.
function SafeZoneService.isPlayerSafe(player: Player): boolean
	if not GameConfig.SafeZonePhases[ReplicatedStorage:GetAttribute("Phase")] then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and SafeZoneService.isInsideZone(root.Position)
end

local function updatePlayers()
	for _, player in Players:GetPlayers() do
		local safe = SafeZoneService.isPlayerSafe(player)
		if player:GetAttribute("Safe") ~= safe then
			player:SetAttribute("Safe", safe)
			log(player.Name, safe and "is safe" or "is not safe")
		end
	end
end

function SafeZoneService.start()
	loadZones()
	log("Safe zones loaded:", #zones)
	task.spawn(function()
		while true do
			updatePlayers()
			task.wait(CHECK_INTERVAL)
		end
	end)
end

return SafeZoneService
