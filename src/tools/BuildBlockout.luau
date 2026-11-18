-- BuildBlockout: Studio tool that builds the Milestone 1 map blockout.
-- Run it in edit mode (not during Play) by pasting this into the Command Bar:
--   require(game.ServerStorage.Tools.BuildBlockout:Clone())()
--
-- Safe to re-run: it deletes only the objects it built before (they carry a
-- "Generated" attribute) and builds them again. Objects you add are never touched.
-- To keep a hand-edited generated object, delete its "Generated" attribute.
--
-- Coordinates: the camp is at (0, 0, 0), north is -Z, and the ground's top is at Y = 0.

local GENERATED = "Generated"
local TRAIL_HALF_WIDTH = 6 -- trails are 12 studs wide
local TRAIL_HALF_LENGTH = 95

local COLOR = {
	Grass = Color3.fromRGB(40, 60, 45),
	Trail = Color3.fromRGB(90, 70, 50),
	SafeLight = Color3.fromRGB(255, 200, 110),
	Wood = Color3.fromRGB(105, 75, 50),
	DarkWood = Color3.fromRGB(70, 50, 35),
	Canopy = Color3.fromRGB(30, 55, 35),
}

local SAFE_ZONES = {
	{ Name = "SafeZone_Camp", X = 0, Z = 0, Diameter = 30 },
	{ Name = "SafeZone_North", X = 0, Z = -60, Diameter = 22 },
	{ Name = "SafeZone_West", X = -60, Z = 0, Diameter = 22 },
	{ Name = "SafeZone_East", X = 60, Z = 0, Diameter = 22 },
	{ Name = "SafeZone_South", X = 0, Z = 60, Diameter = 22 },
}

-- Mushroom patch areas: a flat, differently colored clearing at the end of each spoke.
local AREAS = {
	{ Name = "NorthRidge", X = 0, Z = -95, Material = Enum.Material.Slate, Color = Color3.fromRGB(75, 80, 85) },
	{ Name = "WestGrove", X = -95, Z = 0, Material = Enum.Material.LeafyGrass, Color = Color3.fromRGB(60, 85, 55) },
	{ Name = "EastMarsh", X = 95, Z = 0, Material = Enum.Material.Mud, Color = Color3.fromRGB(45, 65, 75) },
}
local AREA_DIAMETER = 24

-- Simple block landmarks. Each table is passed straight to makePart.
local LANDMARKS = {
	Camp = {
		{ Name = "Cabin", Size = Vector3.new(16, 10, 12), Position = Vector3.new(-20, 5, -18), Material = Enum.Material.WoodPlanks, Color = COLOR.DarkWood },
		{ Name = "Crate", Size = Vector3.new(3, 3, 3), Position = Vector3.new(12, 1.5, -16), Material = Enum.Material.Wood, Color = COLOR.Wood },
		{ Name = "Crate", Size = Vector3.new(3, 3, 3), Position = Vector3.new(15.5, 1.5, -15), Orientation = Vector3.new(0, 20, 0), Material = Enum.Material.Wood, Color = COLOR.Wood },
		{ Name = "Crate", Size = Vector3.new(3, 3, 3), Position = Vector3.new(13.5, 4.5, -15.5), Orientation = Vector3.new(0, 10, 0), Material = Enum.Material.Wood, Color = COLOR.Wood },
	},
	NorthRidge = {
		{ Name = "FallenLog", Shape = Enum.PartType.Cylinder, Size = Vector3.new(18, 3, 3), Position = Vector3.new(-16, 1.5, -82), Orientation = Vector3.new(0, 25, 0), Material = Enum.Material.Wood, Color = COLOR.DarkWood },
	},
	WestGrove = {
		{ Name = "BigStump", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 9, 9), Position = Vector3.new(-95, 2, -16), Orientation = Vector3.new(0, 0, 90), Material = Enum.Material.Wood, Color = COLOR.Wood },
	},
	EastMarsh = {
		{ Name = "LeaningDeadTree", Size = Vector3.new(2, 24, 2), Position = Vector3.new(97, 11, 16), Orientation = Vector3.new(0, 0, -20), Material = Enum.Material.Wood, Color = Color3.fromRGB(80, 80, 75) },
	},
	Trailhead = {
		{ Name = "GatePost", Size = Vector3.new(1.5, 12, 1.5), Position = Vector3.new(-7.5, 6, 85), Material = Enum.Material.Wood, Color = COLOR.DarkWood },
		{ Name = "GatePost", Size = Vector3.new(1.5, 12, 1.5), Position = Vector3.new(7.5, 6, 85), Material = Enum.Material.Wood, Color = COLOR.DarkWood },
		{ Name = "GateBeam", Size = Vector3.new(18, 1.5, 1.5), Position = Vector3.new(0, 12, 85), Material = Enum.Material.Wood, Color = COLOR.DarkWood },
	},
}

-- Trees grow in clusters. A fixed seed puts them in the same spots on every run.
local TREES = {
	Seed = 7,
	TrailGap = 4, -- minimum studs between a trunk and a trail edge
	Spacing = 8, -- minimum studs between two trunks
	Clusters = {
		{ X = -40, Z = -40, Count = 3 }, { X = 40, Z = -40, Count = 3 },
		{ X = -40, Z = 40, Count = 3 }, { X = 40, Z = 40, Count = 3 },
		{ X = -95, Z = -30, Count = 2 }, { X = -95, Z = 30, Count = 2 },
		{ X = 95, Z = -30, Count = 2 }, { X = 95, Z = 30, Count = 2 },
		{ X = -28, Z = -100, Count = 2 }, { X = 28, Z = -100, Count = 2 },
		{ X = -24, Z = 105, Count = 2 }, { X = 24, Z = 105, Count = 2 },
	},
	ClusterRadius = 12,
	TrunkRadius = 1.5,
}

-- Places where a tree must not grow: { X, Z, Radius }.
local TREE_KEEPOUT = {
	{ X = -20, Z = -18, Radius = 13 }, -- cabin
	{ X = 14, Z = -15, Radius = 5 }, -- crates
	{ X = -16, Z = -82, Radius = 11 }, -- fallen log
	{ X = -95, Z = -16, Radius = 7 }, -- stump
	{ X = 97, Z = 16, Radius = 6 }, -- dead tree
}
for _, zone in SAFE_ZONES do
	table.insert(TREE_KEEPOUT, { X = zone.X, Z = zone.Z, Radius = zone.Diameter / 2 + 4 })
end
for _, area in AREAS do
	table.insert(TREE_KEEPOUT, { X = area.X, Z = area.Z, Radius = AREA_DIAMETER / 2 + 2 })
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- Creates an anchored part from a table of Roblox property names. Position and
-- Orientation (in degrees, like the Properties window) are combined into a CFrame.
local function makePart(spec, parent, className)
	local part = Instance.new(className or "Part")
	part.Anchored = true
	part.Shape = spec.Shape or Enum.PartType.Block -- set before Size so Size isn't adjusted afterwards
	for key, value in spec do
		if key ~= "Position" and key ~= "Orientation" and key ~= "Shape" then
			part[key] = value
		end
	end
	local o = spec.Orientation or Vector3.zero
	part.CFrame = CFrame.new(spec.Position) * CFrame.fromOrientation(math.rad(o.X), math.rad(o.Y), math.rad(o.Z))
	part:SetAttribute(GENERATED, true)
	part.Parent = parent
	return part
end

-- Creates a flat round disc on the ground. A cylinder's length runs along X,
-- so tilting it 90 degrees on Z lays it flat and Size.X becomes its thickness.
-- `look` holds extra properties such as Material and Color.
local function makeDisc(name, center, diameter, thickness, look, parent)
	local spec = table.clone(look)
	spec.Name = name
	spec.Shape = Enum.PartType.Cylinder
	spec.Size = Vector3.new(thickness, diameter, diameter)
	spec.Position = center
	spec.Orientation = Vector3.new(0, 0, 90)
	return makePart(spec, parent)
end

-- Finds a folder by name, or creates it. Folders are never deleted, so anything
-- you put inside them is safe.
local function getFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local function clearGenerated(container)
	for _, item in container:GetDescendants() do
		if item:GetAttribute(GENERATED) then
			item:Destroy()
		end
	end
end

local function makeTree(x, z, scale, parent)
	local tree = Instance.new("Model")
	tree.Name = "Tree"
	local height = 20 * scale
	local canopy = 14 * scale
	tree.PrimaryPart = makePart({
		Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, 3, 3),
		Position = Vector3.new(x, height / 2, z), Orientation = Vector3.new(0, 0, 90),
		Material = Enum.Material.Wood, Color = COLOR.Wood,
	}, tree)
	makePart({
		Name = "Canopy", Shape = Enum.PartType.Ball, Size = Vector3.one * canopy,
		Position = Vector3.new(x, height + canopy / 2 - 3, z),
		Material = Enum.Material.Grass, Color = COLOR.Canopy,
	}, tree)
	tree:SetAttribute(GENERATED, true)
	tree.Parent = parent
end

-- True if a trunk at (x, z) stays clear of trails, keep-out zones, the map edge and other trees.
local function isTreeSpotClear(x, z, placed)
	local trailMargin = TRAIL_HALF_WIDTH + TREES.TrailGap + TREES.TrunkRadius
	local lengthMargin = TRAIL_HALF_LENGTH + TREES.TrailGap + TREES.TrunkRadius
	local onNorthSouthTrail = math.abs(x) < trailMargin and math.abs(z) < lengthMargin
	local onEastWestTrail = math.abs(z) < trailMargin and math.abs(x) < lengthMargin
	if onNorthSouthTrail or onEastWestTrail or math.abs(x) > 124 or math.abs(z) > 124 then
		return false
	end
	for _, zone in TREE_KEEPOUT do
		if Vector2.new(x - zone.X, z - zone.Z).Magnitude < zone.Radius then
			return false
		end
	end
	for _, spot in placed do
		if (spot - Vector2.new(x, z)).Magnitude < TREES.Spacing then
			return false
		end
	end
	return true
end

--------------------------------------------------------------------------------
-- Builders
--------------------------------------------------------------------------------

local function buildGround(map)
	makePart({
		Name = "Ground", Size = Vector3.new(260, 16, 260), Position = Vector3.new(0, -8, 0),
		Material = Enum.Material.Grass, Color = COLOR.Grass,
	}, map)
	local trails = getFolder(map, "Trails")
	local width = TRAIL_HALF_WIDTH * 2
	local length = TRAIL_HALF_LENGTH * 2
	local trailSizes = {
		Trail_NorthSouth = Vector3.new(width, 0.2, length),
		Trail_EastWest = Vector3.new(length, 0.2, width),
	}
	for name, size in trailSizes do
		makePart({
			Name = name, Size = size, Position = Vector3.new(0, 0.1, 0),
			Material = Enum.Material.Ground, Color = COLOR.Trail,
		}, trails)
	end
end

local function buildSafeZones(safeZones)
	local look = { Material = Enum.Material.Neon, Color = COLOR.SafeLight, Transparency = 0.5, CanCollide = false }
	for _, zone in SAFE_ZONES do
		local center = Vector3.new(zone.X, 0.3, zone.Z)
		local disc = makeDisc(zone.Name, center, zone.Diameter, 0.4, look, safeZones)
		local light = Instance.new("PointLight")
		light.Brightness = 2
		light.Range = 30
		light.Color = COLOR.SafeLight
		light.Parent = disc
	end
end

local function buildAreasAndLandmarks(map)
	for _, area in AREAS do
		local folder = getFolder(map, area.Name)
		local center = Vector3.new(area.X, 0.05, area.Z)
		makeDisc(area.Name .. "_Patch", center, AREA_DIAMETER, 0.1, { Material = area.Material, Color = area.Color }, folder)
	end
	for folderName, parts in LANDMARKS do
		local folder = getFolder(map, folderName)
		for _, spec in parts do
			makePart(spec, folder)
		end
	end
	makePart({
		Name = "Spawn", Size = Vector3.new(6, 1, 6), Position = Vector3.new(0, 0.5, 95),
		Material = Enum.Material.Slate, Color = COLOR.Trail, Neutral = true,
	}, getFolder(map, "Trailhead"), "SpawnLocation")
end

local function buildTrees(map)
	local folder = getFolder(map, "Trees")
	local rng = Random.new(TREES.Seed)
	local placed = {}
	for _, cluster in TREES.Clusters do
		for _ = 1, cluster.Count do
			for _attempt = 1, 30 do
				local x = cluster.X + rng:NextNumber(-TREES.ClusterRadius, TREES.ClusterRadius)
				local z = cluster.Z + rng:NextNumber(-TREES.ClusterRadius, TREES.ClusterRadius)
				if isTreeSpotClear(x, z, placed) then
					table.insert(placed, Vector2.new(x, z))
					makeTree(x, z, rng:NextNumber(0.85, 1.25), folder)
					break
				end
			end
		end
	end
	return #placed
end

-- Studio's Baseplate template adds these. They would overlap the new ground and spawn.
local function removeTemplateObjects()
	for _, name in { "Baseplate", "SpawnLocation" } do
		local item = workspace:FindFirstChild(name)
		if item and not item:GetAttribute(GENERATED) then
			item:Destroy()
			print("[BuildBlockout] Removed template object:", name)
		end
	end
end

return function()
	local map = getFolder(workspace, "Map")
	local safeZones = getFolder(workspace, "SafeZones")
	clearGenerated(map)
	clearGenerated(safeZones)
	removeTemplateObjects()

	buildGround(map)
	buildSafeZones(safeZones)
	buildAreasAndLandmarks(map)
	local treeCount = buildTrees(map)

	print(("[BuildBlockout] Done: %d safe zones, %d trees. Save the place with Ctrl+S."):format(#SAFE_ZONES, treeCount))
end
