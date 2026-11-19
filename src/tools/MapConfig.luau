-- MapConfig: every number and colour the map generator (BuildMap) uses, in one place.
-- Coordinates: the camp is at (0, 0, 0), north is -Z, and the ground's top is at Y = 0.

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local MapConfig = {}

MapConfig.Trail = {
	HalfWidth = 6, -- trails are 12 studs wide
	HalfLength = 95,
}

MapConfig.Bounds = {
	Playable = 120, -- trees, rocks and mushrooms stay inside +/- this
	Wall = 126, -- invisible walls stop players here
	Backdrop = 148, -- trees beyond the walls, so the forest seems endless
}

MapConfig.Color = {
	Trail = rgb(92, 74, 56),
	SafeLight = rgb(255, 196, 110),
	Wood = rgb(96, 70, 50),
	DarkWood = rgb(58, 42, 32),
	DeadWood = rgb(88, 84, 78),
	Stone = rgb(70, 76, 74),
	Metal = rgb(40, 38, 36),
	Bone = rgb(215, 208, 190),
	PineGreens = { rgb(30, 56, 46), rgb(26, 50, 44), rgb(36, 62, 50), rgb(32, 54, 52) },
}

-- Terrain materials and the colours they are tinted.
MapConfig.TerrainColors = {
	[Enum.Material.Grass] = rgb(44, 70, 54),
	[Enum.Material.LeafyGrass] = rgb(52, 80, 52),
	[Enum.Material.Ground] = rgb(84, 68, 52),
	[Enum.Material.Mud] = rgb(52, 58, 56),
	[Enum.Material.Rock] = rgb(84, 90, 92),
	[Enum.Material.Slate] = rgb(74, 80, 86),
}

MapConfig.SafeZones = {
	{ Name = "SafeZone_Camp", X = 0, Z = 0, Diameter = 30, Stones = 12 },
	{ Name = "SafeZone_North", X = 0, Z = -60, Diameter = 22, Stones = 9 },
	{ Name = "SafeZone_West", X = -60, Z = 0, Diameter = 22, Stones = 9 },
	{ Name = "SafeZone_East", X = 60, Z = 0, Diameter = 22, Stones = 9 },
	{ Name = "SafeZone_South", X = 0, Z = 60, Diameter = 22, Stones = 9 },
}
MapConfig.SafeLight = {
	FloorGlowTransparency = 0.65, -- the glowing circle on the ground when shown
	LightRange = 30,
	LightBrightness = 2.2,
	BeaconHeight = 8,
}

-- Mushroom patch areas at the end of each spoke. Material is painted onto the terrain.
MapConfig.Areas = {
	{ Name = "NorthRidge", X = 0, Z = -95, Material = Enum.Material.Slate },
	{ Name = "WestGrove", X = -95, Z = 0, Material = Enum.Material.LeafyGrass },
	{ Name = "EastMarsh", X = 95, Z = 0, Material = Enum.Material.Mud },
}
MapConfig.AreaDiameter = 26

-- Invisible markers where the server spawns mushrooms each round (Workspace.MushroomSpawns).
-- Type must match a key in src/shared/MushroomConfig.luau.
-- Mooncaps sit beside the trails; Ember Morels at the grove and cabin edges;
-- Guardian Caps in the farthest patches (more risk for a better reward).
MapConfig.MushroomSpawns = {
	{ Name = "WestGrove_1", X = -86, Z = 9, Type = "Mooncap" },
	{ Name = "WestGrove_2", X = -100, Z = -8, Type = "Mooncap" },
	{ Name = "SouthTrail_1", X = 9, Z = 38, Type = "Mooncap" },
	{ Name = "NorthTrail_1", X = -9, Z = -38, Type = "Mooncap" },
	{ Name = "NorthTrail_2", X = 9, Z = -78, Type = "Mooncap" },
	{ Name = "EastTrail_1", X = 38, Z = 9, Type = "Mooncap" },
	{ Name = "EastTrail_2", X = 78, Z = -9, Type = "Mooncap" },
	{ Name = "WestTrail_1", X = -38, Z = -9, Type = "Mooncap" },
	{ Name = "CabinEdge", X = -31, Z = -27, Type = "EmberMorel" },
	{ Name = "WestGrove_Ember1", X = -106, Z = 12, Type = "EmberMorel" },
	{ Name = "WestGrove_Ember2", X = -84, Z = -23, Type = "EmberMorel" },
	{ Name = "NorthRidge_Guardian", X = 10, Z = -104, Type = "GuardianCap" },
	{ Name = "EastMarsh_Guardian", X = 106, Z = -10, Type = "GuardianCap" },
}

-- Invisible dens where the monster can appear (Workspace.MonsterSpawns).
-- They sit in the forest between the trails, away from the safe lights.
MapConfig.MonsterDens = {
	{ Name = "Den_NW", X = -40, Z = -40 }, { Name = "Den_NE", X = 40, Z = -40 },
	{ Name = "Den_SW", X = -40, Z = 40 }, { Name = "Den_SE", X = 40, Z = 40 },
	{ Name = "Den_FarWest", X = -105, Z = -45 }, { Name = "Den_FarEast", X = 105, Z = 45 },
	{ Name = "Den_FarNorth", X = 45, Z = -110 }, { Name = "Den_FarSouth", X = -45, Z = 110 },
}

-- Path lamps (Workspace.PathLights) stand beside each trail spoke and go dark during Blackout.
-- Distances are measured from the camp along the spoke; lamps alternate sides of the trail.
MapConfig.Lamps = {
	Distances = { 28, 44, 80 }, -- avoids the safe zones at 60 and the camp's edge at 15
	SideOffset = 8.5, -- studs from the trail's centre line (just off the trail)
	Spokes = {
		{ Name = "N", Direction = Vector2.new(0, -1) },
		{ Name = "W", Direction = Vector2.new(-1, 0) },
		{ Name = "E", Direction = Vector2.new(1, 0) },
		{ Name = "S", Direction = Vector2.new(0, 1) },
	},
	LanternColor = rgb(255, 170, 90),
}

-- The forest. Trees are scattered on a jittered grid; a fixed seed gives the same forest every run.
MapConfig.Forest = {
	Seed = 7,
	CellSize = 10, -- one tree candidate per cell
	Chance = 0.55, -- chance a cell gets a tree (if the spot is clear)
	DeadTreeChance = 0.1,
	TrailGap = 3, -- studs between a trunk and a trail edge
	Spacing = 7, -- minimum studs between two trunks
	ScaleMin = 0.8,
	ScaleMax = 1.45,
	RockCount = 45,
}

-- Places where trees and rocks must not appear: { X, Z, Radius }. Safe zones, areas,
-- mushroom spots and lamps are added automatically by the generator.
MapConfig.Keepout = {
	{ X = -20, Z = -18, Radius = 13 }, -- cabin
	{ X = 14, Z = -15, Radius = 5 }, -- crates
	{ X = -16, Z = -82, Radius = 11 }, -- fallen log
	{ X = 22, Z = -90, Radius = 8 }, -- split pine
	{ X = -95, Z = -16, Radius = 9 }, -- stump and roots
	{ X = 97, Z = 16, Radius = 8 }, -- dead tree
	{ X = 0, Z = 92, Radius = 14 }, -- trailhead gate and spawn
	{ X = 14, Z = 86, Radius = 5 }, -- trailhead sign
	{ X = 19, Z = 19, Radius = 4 }, -- camp map board
}

return MapConfig
