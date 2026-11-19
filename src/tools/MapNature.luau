-- MapNature: the natural parts of the map - terrain ground, trails, hills, the pine
-- forest, rocks, and the dressing of each area (grove roots and flowers, marsh puddles
-- and reeds, the split pine on the ridge).

local ServerStorage = game:GetService("ServerStorage")
local Tools = ServerStorage.Tools
local MapConfig = require(Tools.MapConfig:Clone())
local MapKit = require(Tools.MapKit:Clone())

local COLOR = MapConfig.Color
local FOREST = MapConfig.Forest
local BOUNDS = MapConfig.Bounds
local TRAIL = MapConfig.Trail

local MapNature = {}

--------------------------------------------------------------------------------
-- Terrain
--------------------------------------------------------------------------------

-- Repaints part of the ground's top layer from one material to another.
local function paint(min: Vector3, max: Vector3, from: Enum.Material, to: Enum.Material)
	local region = Region3.new(min, max):ExpandToGrid(4)
	workspace.Terrain:ReplaceMaterial(region, 4, from, to)
end

-- Repaints a round patch of ground (whatever grass or dirt is there) without changing
-- its height, one 4x4-stud terrain cell at a time.
local GROUND_MATERIALS = { Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground }
local function paintCircle(x: number, z: number, radius: number, to: Enum.Material)
	for cx = math.floor((x - radius) / 4) * 4, x + radius, 4 do
		for cz = math.floor((z - radius) / 4) * 4, z + radius, 4 do
			if Vector2.new(cx + 2 - x, cz + 2 - z).Magnitude <= radius then
				for _, from in GROUND_MATERIALS do
					paint(Vector3.new(cx, -8, cz), Vector3.new(cx + 4, 0, cz + 4), from, to)
				end
			end
		end
	end
end

-- Ground (top at Y = 0), dirt trails, painted patch areas and grassy hills around the edge.
-- Note: this REPLACES all terrain in the place.
function MapNature.buildTerrain(rng: Random)
	local terrain = workspace.Terrain
	terrain:Clear()
	for material, color in MapConfig.TerrainColors do
		terrain:SetMaterialColor(material, color)
	end
	pcall(function()
		terrain.Decoration = true -- swaying grass blades on Grass terrain
	end)

	-- Smooth terrain's surface sits 2 studs above the top of a filled block, so the
	-- block's top is at -2 to put the walkable ground at Y = 0.
	local size = (BOUNDS.Backdrop + 8) * 2
	terrain:FillBlock(CFrame.new(0, -10, 0), Vector3.new(size, 16, size), Enum.Material.Grass)

	-- Trails: dirt down the middle with leafy edges.
	local w, l = TRAIL.HalfWidth, TRAIL.HalfLength
	paint(Vector3.new(-w - 4, -8, -l), Vector3.new(w + 4, 0, l), Enum.Material.Grass, Enum.Material.LeafyGrass)
	paint(Vector3.new(-l, -8, -w - 4), Vector3.new(l, 0, w + 4), Enum.Material.Grass, Enum.Material.LeafyGrass)
	paint(Vector3.new(-w, -8, -l), Vector3.new(w, 0, l), Enum.Material.LeafyGrass, Enum.Material.Ground)
	paint(Vector3.new(-l, -8, -w), Vector3.new(l, 0, w), Enum.Material.LeafyGrass, Enum.Material.Ground)
	paintCircle(0, 0, 15, Enum.Material.Ground) -- trampled camp clearing
	for _, area in MapConfig.Areas do
		paintCircle(area.X, area.Z, MapConfig.AreaDiameter / 2, area.Material)
	end

	-- Rolling hills just outside the walls frame the map and hide its edge.
	local ring = BOUNDS.Wall + 14
	for t = -BOUNDS.Backdrop, BOUNDS.Backdrop, 14 do
		for _, spot in { Vector2.new(t, -ring), Vector2.new(t, ring), Vector2.new(-ring, t), Vector2.new(ring, t) } do
			local radius = rng:NextNumber(14, 24)
			local material = rng:NextNumber() < 0.25 and Enum.Material.Rock or Enum.Material.Grass
			terrain:FillBall(Vector3.new(spot.X, -radius * 0.45, spot.Y), radius, material)
		end
	end
end

--------------------------------------------------------------------------------
-- Trees and rocks
--------------------------------------------------------------------------------

-- Builds the list of keep-out circles: hand-written ones plus safe zones, areas,
-- mushroom spots and lamps.
local function buildKeepout()
	local keepout = table.clone(MapConfig.Keepout)
	for _, zone in MapConfig.SafeZones do
		table.insert(keepout, { X = zone.X, Z = zone.Z, Radius = zone.Diameter / 2 + 4 })
	end
	for _, area in MapConfig.Areas do
		table.insert(keepout, { X = area.X, Z = area.Z, Radius = MapConfig.AreaDiameter / 2 + 1 })
	end
	for _, spawn in MapConfig.MushroomSpawns do
		table.insert(keepout, { X = spawn.X, Z = spawn.Z, Radius = 5 })
	end
	for _, spoke in MapConfig.Lamps.Spokes do
		for _, distance in MapConfig.Lamps.Distances do
			local onTrail = spoke.Direction * distance
			table.insert(keepout, { X = onTrail.X, Z = onTrail.Y, Radius = MapConfig.Lamps.SideOffset + 3 })
		end
	end
	return keepout
end

-- True if a trunk at (x, z) stays clear of the trails and every keep-out circle.
local function isSpotClear(x: number, z: number, keepout): boolean
	local margin = TRAIL.HalfWidth + FOREST.TrailGap
	local onNorthSouthTrail = math.abs(x) < margin and math.abs(z) < TRAIL.HalfLength + FOREST.TrailGap
	local onEastWestTrail = math.abs(z) < margin and math.abs(x) < TRAIL.HalfLength + FOREST.TrailGap
	if onNorthSouthTrail or onEastWestTrail then
		return false
	end
	for _, zone in keepout do
		if Vector2.new(x - zone.X, z - zone.Z).Magnitude < zone.Radius then
			return false
		end
	end
	return true
end

-- A dark pine: a trunk and three stacked pyramids, each turned a little differently.
local function makePine(x: number, z: number, scale: number, rng: Random, parent: Instance)
	local tree = MapKit.model("Pine", parent)
	local trunkLook = { Material = Enum.Material.Wood, Color = COLOR.DarkWood }
	local trunkHeight = 15 * scale
	tree.PrimaryPart = MapKit.limb("Trunk", Vector3.new(x, -1, z), Vector3.new(x, trunkHeight, z), 1.6 * scale, trunkLook, tree)

	local green = COLOR.PineGreens[rng:NextInteger(1, #COLOR.PineGreens)]
	local layers = { -- { width, height, bottom }
		{ 12, 8.5, 4 },
		{ 9.5, 7.5, 8.5 },
		{ 6.5, 6.5, 12.5 },
	}
	for i, layer in layers do
		local look = { Material = Enum.Material.Grass, Color = green:Lerp(Color3.new(1, 1, 1), (i - 1) * 0.03), CastShadow = true }
		local base = Vector3.new(x, layer[3] * scale, z)
		MapKit.pyramid("Needles", base, layer[1] * scale, layer[2] * scale, rng:NextNumber(0, math.pi / 2), look, tree)
	end
end

-- A dead, leaning tree with crooked bare branches - a spooky silhouette in the fog.
local function makeDeadTree(x: number, z: number, scale: number, rng: Random, parent: Instance, lean: Vector3?)
	local tree = MapKit.model("DeadTree", parent)
	local look = { Material = Enum.Material.Wood, Color = COLOR.DeadWood }
	local base = Vector3.new(x, -1, z)
	local top = base + Vector3.new(0, 17 * scale, 0) + (lean or Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2)))
	tree.PrimaryPart = MapKit.limb("Trunk", base, top, 1.5 * scale, look, tree)

	for _ = 1, rng:NextInteger(3, 5) do
		local start = base:Lerp(top, rng:NextNumber(0.45, 0.9))
		local angle = rng:NextNumber(0, math.pi * 2)
		local length = rng:NextNumber(4, 7) * scale
		local direction = Vector3.new(math.cos(angle), rng:NextNumber(0.5, 1.1), math.sin(angle)).Unit
		local tip = start + direction * length
		MapKit.limb("Branch", start, tip, 0.55 * scale, look, tree)
		-- a small twig off the end makes it look less straight
		local twig = tip + Vector3.new(rng:NextNumber(-1.5, 1.5), rng:NextNumber(0.8, 2), rng:NextNumber(-1.5, 1.5)) * scale
		MapKit.limb("Twig", tip, twig, 0.3 * scale, look, tree)
	end
	return tree
end
MapNature.makeDeadTree = makeDeadTree

-- Scatters trees on a jittered grid, inside the playable area and as a backdrop beyond the walls.
function MapNature.buildForest(parent: Instance, rng: Random): number
	local keepout = buildKeepout()
	local placed = {}
	local function farFromOthers(spot: Vector2): boolean
		for _, other in placed do
			if (other - spot).Magnitude < FOREST.Spacing then
				return false
			end
		end
		return true
	end

	local cell = FOREST.CellSize
	for gx = -BOUNDS.Backdrop, BOUNDS.Backdrop - cell, cell do
		for gz = -BOUNDS.Backdrop, BOUNDS.Backdrop - cell, cell do
			local x = gx + rng:NextNumber(0, cell)
			local z = gz + rng:NextNumber(0, cell)
			local edge = math.max(math.abs(x), math.abs(z))
			local inside = edge <= BOUNDS.Playable
			local backdrop = edge >= BOUNDS.Wall + 3
			local chance = backdrop and 0.85 or FOREST.Chance
			local scale = rng:NextNumber(FOREST.ScaleMin, FOREST.ScaleMax)
			local roll = rng:NextNumber()
			if (inside or backdrop) and roll < chance and (backdrop or isSpotClear(x, z, keepout)) then
				local spot = Vector2.new(x, z)
				if farFromOthers(spot) then
					table.insert(placed, spot)
					if inside and rng:NextNumber() < FOREST.DeadTreeChance then
						makeDeadTree(x, z, scale, rng, parent)
					else
						makePine(x, z, backdrop and scale * 1.2 or scale, rng, parent)
					end
					if #placed % 25 == 0 then
						task.wait() -- let Studio breathe while building hundreds of parts
					end
				end
			end
		end
	end

	-- Rocks: half-buried terrain boulders between the trees.
	for _ = 1, FOREST.RockCount do
		local x = rng:NextNumber(-BOUNDS.Playable, BOUNDS.Playable)
		local z = rng:NextNumber(-BOUNDS.Playable, BOUNDS.Playable)
		if isSpotClear(x, z, keepout) then
			local radius = rng:NextNumber(1.2, 2.8)
			workspace.Terrain:FillBall(Vector3.new(x, -radius * 0.35, z), radius, Enum.Material.Rock)
		end
	end
	return #placed
end

--------------------------------------------------------------------------------
-- Area dressing
--------------------------------------------------------------------------------

-- West Grove: thick roots around the big stump and pale flowers.
local function dressGrove(parent: Instance, rng: Random)
	local stump = Vector3.new(-95, 0, -16)
	local rootLook = { Material = Enum.Material.Wood, Color = COLOR.Wood }
	for i = 1, 6 do
		local angle = i / 6 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local from = stump + direction * 3.5 + Vector3.new(0, 1.6, 0)
		local to = stump + direction * rng:NextNumber(7, 9) + Vector3.new(0, -0.4, 0)
		MapKit.limb("Root", from, to, rng:NextNumber(0.9, 1.4), rootLook, parent)
	end

	local petals = { Color3.fromRGB(228, 222, 240), Color3.fromRGB(205, 225, 235), Color3.fromRGB(235, 228, 210) }
	local stemLook = { Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(70, 100, 70), CanCollide = false, CastShadow = false }
	local placed = 0
	while placed < 28 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local spot = Vector3.new(-95, 0, 0) + Vector3.new(math.cos(angle), 0, math.sin(angle)) * rng:NextNumber(4, 16)
		if math.abs(spot.Z) > 7 then -- not on the trail
			placed += 1
			local height = rng:NextNumber(0.6, 1.2)
			MapKit.part(MapKit.with(stemLook, { Name = "Stem", Size = Vector3.new(0.12, height, 0.12), Position = spot + Vector3.new(0, height / 2, 0) }), parent)
			MapKit.part({
				Name = "Flower", Shape = Enum.PartType.Ball, Size = Vector3.one * rng:NextNumber(0.35, 0.55),
				Position = spot + Vector3.new(0, height, 0), Material = Enum.Material.SmoothPlastic,
				Color = petals[rng:NextInteger(1, #petals)], CanCollide = false, CastShadow = false,
			}, parent)
		end
	end
end

-- East Marsh: still puddles that catch the light, clumps of reeds and a leaning dead tree.
local function dressMarsh(parent: Instance, rng: Random)
	local puddles = { { 87, 11, 8 }, { 101, 13, 6 }, { 89, -13, 9 }, { 101, -21, 6 }, { 113, 5, 7 }, { 82, -22, 5 } }
	local waterLook = { Material = Enum.Material.Glass, Color = Color3.fromRGB(30, 55, 70), Transparency = 0.15, Reflectance = 0.35, CanCollide = false, CastShadow = false }
	local reedLook = { Material = Enum.Material.Grass, Color = Color3.fromRGB(86, 96, 62), CanCollide = false }
	for i, puddle in puddles do
		local center = Vector3.new(puddle[1], 0.06, puddle[2])
		MapKit.disc("Puddle" .. i, center, puddle[3], 0.1, waterLook, parent)
		for _ = 1, rng:NextInteger(4, 7) do
			local angle = rng:NextNumber(0, math.pi * 2)
			local foot = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * (puddle[3] / 2 + rng:NextNumber(0, 1.2))
			local tip = foot + Vector3.new(rng:NextNumber(-0.6, 0.6), rng:NextNumber(2.5, 4.5), rng:NextNumber(-0.6, 0.6))
			MapKit.limb("Reed", foot, tip, 0.18, reedLook, parent)
		end
	end
	makeDeadTree(97, 16, 1.35, rng, parent, Vector3.new(-5, 0, 2))
end

-- North Ridge: a big pine split into two trunks, and rocky outcrops.
local function dressRidge(parent: Instance, rng: Random)
	local tree = MapKit.model("SplitPine", parent)
	local trunkLook = { Material = Enum.Material.Wood, Color = COLOR.DarkWood }
	local base = Vector3.new(22, -1, -90)
	local tops = { Vector3.new(17, 20, -93), Vector3.new(28, 18, -86) }
	for i, top in tops do
		MapKit.limb("Trunk" .. i, base, top, 2.2, trunkLook, tree)
		local look = { Material = Enum.Material.Grass, Color = COLOR.PineGreens[i] }
		MapKit.pyramid("Needles", top - Vector3.new(0, 9, 0), 10, 8, rng:NextNumber(0, 1.5), look, tree)
		MapKit.pyramid("Needles", top - Vector3.new(0, 4, 0), 7, 7, rng:NextNumber(0, 1.5), look, tree)
	end
	for _, rock in { { -12, -108, 5 }, { 18, -113, 4 }, { -22, -100, 3.5 }, { 12, -82, 2.5 } } do
		workspace.Terrain:FillBall(Vector3.new(rock[1], -rock[3] * 0.3, rock[2]), rock[3], Enum.Material.Slate)
	end
end

function MapNature.dressAreas(map: Instance, rng: Random)
	dressGrove(MapKit.folder(map, "WestGrove"), rng)
	dressMarsh(MapKit.folder(map, "EastMarsh"), rng)
	dressRidge(MapKit.folder(map, "NorthRidge"), rng)
end

return MapNature
