-- MapProps: the built objects of the map - the ranger camp, landmarks, trailhead,
-- path lamps, the safe lights (with their standing stones and beacon), spawn markers,
-- invisible boundary walls, and the starting night lighting seen in Studio.
--
-- Safe-light pieces that should only appear from the Warning onward are tagged
-- "SafeGlow" (CollectionService); the client's LightingController shows and hides them.

local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local Tools = ServerStorage.Tools
local MapConfig = require(Tools.MapConfig:Clone())
local MapKit = require(Tools.MapKit:Clone())

local COLOR = MapConfig.Color
local SAFE = MapConfig.SafeLight

local MapProps = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- A SurfaceGui sign: `lines` are { text, size } pairs written on the front (-Z) face.
local function writeSign(part: BasePart, lines)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0.7
	gui.PixelsPerStud = 40
	gui.Parent = part
	local layout = Instance.new("UIListLayout")
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = gui
	for _, line in lines do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, line[2], 0)
		label.Font = Enum.Font.Fondamento
		label.Text = line[1]
		label.TextScaled = true
		label.TextColor3 = rgb(225, 210, 175)
		label.Parent = gui
	end
end

--------------------------------------------------------------------------------
-- Camp
--------------------------------------------------------------------------------

-- The old ranger cabin: plank walls with a doorway and window, and a broken roof.
local function buildCabin(parent: Instance)
	local cabin = MapKit.model("RangerCabin", parent)
	local plank = { Material = Enum.Material.WoodPlanks, Color = COLOR.DarkWood }
	local wood = { Material = Enum.Material.Wood, Color = COLOR.Wood }
	local function wall(name, size, position)
		return MapKit.part(MapKit.with(plank, { Name = name, Size = size, Position = position }), cabin)
	end
	-- The cabin spans X -28..-12 and Z -24..-12; walls are 8 tall.
	MapKit.part(MapKit.with(wood, { Name = "Floor", Size = Vector3.new(16, 0.6, 12), Position = Vector3.new(-20, 0.3, -18) }), cabin)
	wall("BackWall", Vector3.new(16, 8, 0.8), Vector3.new(-20, 4, -23.6))
	wall("WestWall", Vector3.new(0.8, 8, 12), Vector3.new(-27.6, 4, -18))
	wall("EastWallLow", Vector3.new(0.8, 3, 12), Vector3.new(-12.4, 1.5, -18))
	wall("EastWallTop", Vector3.new(0.8, 2, 12), Vector3.new(-12.4, 7, -18))
	wall("EastWallSideA", Vector3.new(0.8, 3, 4), Vector3.new(-12.4, 4.5, -22))
	wall("EastWallSideB", Vector3.new(0.8, 3, 4), Vector3.new(-12.4, 4.5, -14)) -- leaves a window in the middle
	wall("FrontWallLeft", Vector3.new(6, 8, 0.8), Vector3.new(-25, 4, -12.4))
	wall("FrontWallRight", Vector3.new(5, 5, 0.8), Vector3.new(-14.5, 2.5, -12.4)) -- broken: shorter
	wall("Lintel", Vector3.new(5, 1.2, 0.8), Vector3.new(-19.5, 7.4, -12.4)) -- doorway below

	-- Gable roof: two wedges meeting at a ridge along X. The south half has a hole.
	local roof = { Material = Enum.Material.WoodPlanks, Color = rgb(48, 36, 30) }
	MapKit.part(MapKit.with(roof, { Name = "RoofNorth", Size = Vector3.new(17.5, 4.5, 6.8), Position = Vector3.new(-20, 10.25, -21.4) }), cabin, "WedgePart")
	MapKit.part(MapKit.with(roof, { Name = "RoofSouth", Size = Vector3.new(10, 4.5, 6.8), Position = Vector3.new(-23.7, 10.25, -14.6), Orientation = Vector3.new(0, 180, 0) }), cabin, "WedgePart")
	MapKit.part(MapKit.with(wood, { Name = "FallenBeam", Size = Vector3.new(0.6, 0.6, 9), Position = Vector3.new(-15, 3.2, -16), Orientation = Vector3.new(35, 10, 0) }), cabin)
	MapKit.part({ Name = "Chimney", Size = Vector3.new(2.2, 13, 2.2), Position = Vector3.new(-27, 6.5, -21.5), Material = Enum.Material.Cobblestone, Color = COLOR.Stone }, cabin)
end

local function buildCamp(map: Instance)
	local camp = MapKit.folder(map, "Camp")
	buildCabin(camp)

	local crate = { Material = Enum.Material.WoodPlanks, Color = COLOR.Wood }
	MapKit.part(MapKit.with(crate, { Name = "Crate", Size = Vector3.new(3, 3, 3), Position = Vector3.new(12, 1.5, -16) }), camp)
	MapKit.part(MapKit.with(crate, { Name = "Crate", Size = Vector3.new(3, 3, 3), Position = Vector3.new(15.5, 1.5, -15), Orientation = Vector3.new(0, 20, 0) }), camp)
	MapKit.part(MapKit.with(crate, { Name = "Crate", Size = Vector3.new(2.6, 2.6, 2.6), Position = Vector3.new(13.5, 4.3, -15.5), Orientation = Vector3.new(0, 10, 0) }), camp)
	MapKit.part({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.2, 2.4, 2.4), Position = Vector3.new(17, 1.6, -11), Orientation = Vector3.new(0, 0, 90), Material = Enum.Material.Wood, Color = rgb(80, 58, 40) }, camp)

	-- Map board facing the trailhead.
	local post = { Material = Enum.Material.Wood, Color = COLOR.DarkWood }
	MapKit.part(MapKit.with(post, { Name = "BoardPost", Size = Vector3.new(0.5, 6, 0.5), Position = Vector3.new(17.5, 3, 19) }), camp)
	MapKit.part(MapKit.with(post, { Name = "BoardPost", Size = Vector3.new(0.5, 6, 0.5), Position = Vector3.new(20.5, 3, 19) }), camp)
	local board = MapKit.part({ Name = "MapBoard", Size = Vector3.new(4.4, 3, 0.3), Position = Vector3.new(19, 4.2, 19.3), Orientation = Vector3.new(0, 180, 0), Material = Enum.Material.WoodPlanks, Color = rgb(120, 96, 66) }, camp)
	writeSign(board, { { "THE HOLLOW PINES", 0.3 }, { "N: Ridge   W: Grove   E: Marsh", 0.22 }, { "When the song stops, find the light.", 0.22 } })
end

--------------------------------------------------------------------------------
-- Landmarks and trailhead
--------------------------------------------------------------------------------

local function buildLandmarks(map: Instance)
	local log = { Material = Enum.Material.Wood, Color = COLOR.DarkWood }
	MapKit.part(MapKit.with(log, { Name = "FallenLog", Shape = Enum.PartType.Cylinder, Size = Vector3.new(20, 3.2, 3.2), Position = Vector3.new(-16, 1.4, -82), Orientation = Vector3.new(0, 25, 0) }), MapKit.folder(map, "NorthRidge"))
	MapKit.part({ Name = "BigStump", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 9, 9), Position = Vector3.new(-95, 1.8, -16), Orientation = Vector3.new(0, 0, 90), Material = Enum.Material.Wood, Color = COLOR.Wood }, MapKit.folder(map, "WestGrove"))

	local trailhead = MapKit.folder(map, "Trailhead")
	local beam = { Material = Enum.Material.Wood, Color = COLOR.DarkWood }
	MapKit.part(MapKit.with(beam, { Name = "GatePost", Size = Vector3.new(1.6, 13, 1.6), Position = Vector3.new(-8, 6.5, 85) }), trailhead)
	MapKit.part(MapKit.with(beam, { Name = "GatePost", Size = Vector3.new(1.6, 13, 1.6), Position = Vector3.new(8, 6.5, 85) }), trailhead)
	MapKit.part(MapKit.with(beam, { Name = "GateBeam", Size = Vector3.new(20, 1.6, 1.6), Position = Vector3.new(0, 12.4, 85), Orientation = Vector3.new(0, 0, -2) }), trailhead)
	local sign = MapKit.part({ Name = "GateSign", Size = Vector3.new(9, 2.2, 0.3), Position = Vector3.new(0, 10.4, 86), Orientation = Vector3.new(0, 180, 0), Material = Enum.Material.WoodPlanks, Color = rgb(110, 86, 60) }, trailhead)
	writeSign(sign, { { "THE HOLLOW PINES", 1 } })
	-- Warning sign beside the path, facing players who just spawned.
	MapKit.part(MapKit.with(beam, { Name = "SignPost", Size = Vector3.new(0.5, 5, 0.5), Position = Vector3.new(14, 2.5, 86.5) }), trailhead)
	local warning = MapKit.part({ Name = "WarningSign", Size = Vector3.new(4.5, 2.4, 0.25), Position = Vector3.new(14, 4.4, 86.3), Material = Enum.Material.WoodPlanks, Color = rgb(110, 86, 60), Orientation = Vector3.new(0, 180, -4) }, trailhead)
	writeSign(warning, { { "The forest listens", 0.4 }, { "to the song.", 0.4 } })

	MapKit.part({
		Name = "Spawn", Size = Vector3.new(6, 1, 6), Position = Vector3.new(0, 0.5, 95),
		Material = Enum.Material.Slate, Color = COLOR.Trail, Neutral = true, Transparency = 0.2,
	}, trailhead, "SpawnLocation")
end

--------------------------------------------------------------------------------
-- Path lamps
--------------------------------------------------------------------------------

-- A wooden post with an arm and a hanging glass lantern. The client's LightingController
-- finds the "Lantern" part (the glowing core) by name to switch it on and off.
local function makeLamp(name: string, position: Vector3, towardTrail: Vector3, parent: Instance)
	local lamp = MapKit.model(name, parent, true)
	local wood = { Material = Enum.Material.Wood, Color = COLOR.DarkWood }
	local metal = { Material = Enum.Material.Metal, Color = COLOR.Metal }
	lamp.PrimaryPart = MapKit.part(MapKit.with(wood, { Name = "Post", Size = Vector3.new(0.6, 9, 0.6), Position = position + Vector3.new(0, 4.5, 0) }), lamp)
	local armEnd = position + towardTrail * 1.8 + Vector3.new(0, 8.6, 0)
	MapKit.limb("Arm", position + Vector3.new(0, 8.6, 0), armEnd, 0.3, wood, lamp)
	local hang = armEnd - Vector3.new(0, 1.6, 0)
	MapKit.part(MapKit.with(metal, { Name = "Chain", Size = Vector3.new(0.08, 0.6, 0.08), Position = armEnd - Vector3.new(0, 0.3, 0) }), lamp)
	MapKit.pyramid("Cap", hang + Vector3.new(0, 0.8, 0), 1.4, 0.5, 0, metal, lamp)
	MapKit.part({ Name = "Cage", Size = Vector3.new(1.1, 1.5, 1.1), Position = hang, Material = Enum.Material.Glass, Color = rgb(255, 210, 160), Transparency = 0.55, CanCollide = false }, lamp)
	local lantern = MapKit.part({ Name = "Lantern", Size = Vector3.new(0.55, 0.85, 0.55), Position = hang, Material = Enum.Material.Neon, Color = MapConfig.Lamps.LanternColor, CanCollide = false, CastShadow = false }, lamp)
	MapKit.add("PointLight", { Brightness = 1.4, Range = 20, Color = MapConfig.Lamps.LanternColor, Shadows = true }, lantern)
end

local function buildPathLights(folder: Instance)
	local lamps = MapConfig.Lamps
	for _, spoke in lamps.Spokes do
		local side = Vector2.new(-spoke.Direction.Y, spoke.Direction.X) -- points across the trail
		for i, distance in lamps.Distances do
			local sign = (i % 2 == 1) and 1 or -1 -- alternate sides
			local spot = spoke.Direction * distance + side * lamps.SideOffset * sign
			local towardTrail = Vector3.new(-side.X * sign, 0, -side.Y * sign)
			makeLamp("PathLamp_" .. spoke.Name .. i, Vector3.new(spot.X, 0, spot.Y), towardTrail, folder)
		end
	end
end

--------------------------------------------------------------------------------
-- Safe lights
--------------------------------------------------------------------------------

-- One safe light: the zone disc (in Workspace.SafeZones, read by the server), a ring of
-- standing stones with glowing runes, and a beacon post whose flame lights the clearing.
-- Everything that glows is tagged "SafeGlow" and stays hidden until the Warning.
local function buildSafeLight(zone, safeZones: Instance, decorFolder: Instance, rng: Random)
	local center = Vector3.new(zone.X, 0, zone.Z)
	local radius = zone.Diameter / 2
	local glow = MapConfig.Color.SafeLight

	local disc = MapKit.disc(zone.Name, center + Vector3.new(0, 0.15, 0), zone.Diameter, 0.3, {
		Material = Enum.Material.Neon, Color = glow, Transparency = SAFE.FloorGlowTransparency,
		CanCollide = false, CanQuery = false, CastShadow = false, Tag = "SafeGlow",
	}, safeZones)
	disc:SetAttribute("GlowTransparency", SAFE.FloorGlowTransparency)

	local decor = MapKit.model(zone.Name .. "_Decor", decorFolder, true)
	local stone = { Material = Enum.Material.Slate, Color = COLOR.Stone }
	for i = 1, zone.Stones do
		local angle = (i / zone.Stones) * math.pi * 2
		local spot = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * (radius + 1)
		local height = rng:NextNumber(2.2, 3.4)
		local facing = CFrame.lookAt(spot, center) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-6, 6)))
		local stonePart = MapKit.part(MapKit.with(stone, { Name = "Stone", Size = Vector3.new(1.4, height, 0.9), CFrame = facing + Vector3.new(0, height / 2 - 0.3, 0) }), decor)
		local rune = MapKit.part({
			Name = "Rune", Size = Vector3.new(0.45, 0.9, 0.05), CFrame = stonePart.CFrame * CFrame.new(0, 0.3, -0.48),
			Material = Enum.Material.Neon, Color = glow, Transparency = 0, CanCollide = false, CastShadow = false, Tag = "SafeGlow",
		}, decor)
		rune:SetAttribute("GlowTransparency", 0)
	end

	-- Beacon: a carved post with a warm flame on top. Its light is what lights the clearing.
	-- The post stands beside the trail, not on it (zones sit on the trails).
	local offset = if zone.Name == "SafeZone_Camp" then Vector3.new(-7, 0, 7) elseif zone.X == 0 then Vector3.new(8, 0, 0) else Vector3.new(0, 0, 8)
	local postSpot = center + offset
	MapKit.part({ Name = "BeaconPost", Size = Vector3.new(0.8, SAFE.BeaconHeight, 0.8), Position = postSpot + Vector3.new(0, SAFE.BeaconHeight / 2, 0), Material = Enum.Material.Wood, Color = COLOR.DarkWood }, decor)
	MapKit.part({ Name = "Bowl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 2.2, 2.2), Position = postSpot + Vector3.new(0, SAFE.BeaconHeight + 0.2, 0), Orientation = Vector3.new(0, 0, 90), Material = Enum.Material.Metal, Color = COLOR.Metal }, decor)
	local flame = MapKit.part({
		Name = "Flame", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.4, Position = postSpot + Vector3.new(0, SAFE.BeaconHeight + 1, 0),
		Material = Enum.Material.Neon, Color = glow, CanCollide = false, CastShadow = false, Tag = "SafeGlow",
	}, decor)
	flame:SetAttribute("GlowTransparency", 0)
	MapKit.add("PointLight", { Brightness = SAFE.LightBrightness, Range = SAFE.LightRange, Color = glow, Shadows = true }, flame)
	MapKit.add("Sound", { Name = "Hum", SoundId = "rbxassetid://9119032767", Looped = true, Volume = 0.18, RollOffMaxDistance = 45, RollOffMinDistance = 8 }, flame)

	-- Fireflies drifting over the whole clearing (from an invisible box).
	local swarm = MapKit.part({
		Name = "Fireflies", Size = Vector3.new(zone.Diameter - 4, 5, zone.Diameter - 4), Position = center + Vector3.new(0, 3, 0),
		Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tag = "SafeGlow",
	}, decor)
	swarm:SetAttribute("GlowTransparency", 1)
	MapKit.add("ParticleEmitter", {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(rgb(255, 230, 150)),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.25), NumberSequenceKeypoint.new(0.8, 0.25), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new(0.1),
		Lifetime = NumberRange.new(3, 5),
		Rate = zone.Diameter * 0.6,
		Speed = NumberRange.new(0.3, 1),
		SpreadAngle = Vector2.new(180, 180),
		RotSpeed = NumberRange.new(-30, 30),
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	}, swarm)
end

local function buildSafeLights(safeZones: Instance, map: Instance, rng: Random)
	local decorFolder = MapKit.folder(map, "SafeLights")
	for _, zone in MapConfig.SafeZones do
		buildSafeLight(zone, safeZones, decorFolder, rng)
	end
end

--------------------------------------------------------------------------------
-- Markers, walls and lighting
--------------------------------------------------------------------------------

-- A marker is a 1-stud invisible cube resting on the ground; the server reads its position.
local function makeMarker(name: string, x: number, z: number, parent: Instance): BasePart
	return MapKit.part({
		Name = name, Size = Vector3.one, Position = Vector3.new(x, 0.5, z),
		Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false,
	}, parent)
end

local function buildMarkers(mushroomFolder: Instance, denFolder: Instance)
	for _, spawn in MapConfig.MushroomSpawns do
		makeMarker(spawn.Name, spawn.X, spawn.Z, mushroomFolder):SetAttribute("MushroomType", spawn.Type)
	end
	for _, den in MapConfig.MonsterDens do
		makeMarker(den.Name, den.X, den.Z, denFolder)
	end
end

-- Invisible walls around the playable area.
local function buildWalls(map: Instance)
	local walls = MapKit.folder(map, "Walls")
	local edge = MapConfig.Bounds.Wall
	local look = { Transparency = 1, CanQuery = false, Size = Vector3.new(edge * 2 + 4, 60, 2) }
	for i, cframe in { CFrame.new(0, 30, -edge), CFrame.new(0, 30, edge), CFrame.new(-edge, 30, 0) * CFrame.Angles(0, math.pi / 2, 0), CFrame.new(edge, 30, 0) * CFrame.Angles(0, math.pi / 2, 0) } do
		MapKit.part(MapKit.with(look, { Name = "Wall" .. i, CFrame = cframe }), walls)
	end
end

-- The night look you see in Studio while editing. During play, the client's
-- LightingController takes over and changes it per phase.
local function setupLighting()
	Lighting.ClockTime = 0
	Lighting.Brightness = 1
	Lighting.Ambient = rgb(30, 40, 45)
	Lighting.OutdoorAmbient = rgb(60, 88, 92)
	Lighting.EnvironmentDiffuseScale = 0.3
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GlobalShadows = true
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
	atmosphere.Density = 0.4
	atmosphere.Offset = 0.1
	atmosphere.Color = rgb(60, 105, 105)
	atmosphere.Decay = rgb(25, 45, 50)
	atmosphere.Glare = 0
	atmosphere.Haze = 1
	local grade = Lighting:FindFirstChild("Grade") or Instance.new("ColorCorrectionEffect", Lighting)
	grade.Name = "Grade"
	grade.Contrast = 0.12
	grade.Saturation = -0.1
	grade.TintColor = rgb(220, 235, 240)
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
	bloom.Intensity = 0.8
	bloom.Size = 30
	bloom.Threshold = 1.6
	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if sunRays then
		sunRays.Enabled = false
	end
end

function MapProps.build(folders, rng: Random)
	buildCamp(folders.Map)
	buildLandmarks(folders.Map)
	buildPathLights(folders.PathLights)
	buildSafeLights(folders.SafeZones, folders.Map, rng)
	buildMarkers(folders.MushroomSpawns, folders.MonsterSpawns)
	buildWalls(folders.Map)
	setupLighting()
end

return MapProps
